import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/erc20_token_info_moralis.dart';
import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/token_utilities.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/currency_groups.dart";
import 'package:cw_core/erc20_token.dart';
import 'package:cake_wallet/entities/spark_conversion.dart';
import 'package:cw_core/utils/homoglyph_normalizer.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

part 'home_settings_view_model.g.dart';

class HomeSettingsViewModel = HomeSettingsViewModelBase with _$HomeSettingsViewModel;

/// Which Stable Balance setting a reconnect was triggered by - a reconnect started to apply a
/// new [HomeSettingsViewModelBase.selectedMaxSlippageBps]/[HomeSettingsViewModelBase.thresholdSats]
/// can fail independently of the on/off toggle itself, and the UI needs to know which row to
/// show "applying"/"failed, reverted" feedback on.
enum StableBalanceSetting { maxSlippage, thresholdSats }

enum StableBalanceConversionOutcome { willConvert, belowMinimum, nothingToConvert, unknown }

/// What turning Stable Balance on or off will convert right away, per the SDK's own rules.
class StableBalanceConversionPreview {
  const StableBalanceConversionPreview(
    this.outcome, {
    this.amount,
    this.minimum,
    this.estimate,
    this.effectiveThreshold,
  });

  static const unknown = StableBalanceConversionPreview(StableBalanceConversionOutcome.unknown);

  final StableBalanceConversionOutcome outcome;

  /// The balance that converts (or falls short), with its unit - "3560 sats", "1 USDB".
  final String? amount;

  /// The minimum [amount] has to reach, in [amount]'s unit.
  final String? minimum;

  /// Rough value of [amount] in the other currency - "$3.00", "1187 sats".
  final String? estimate;

  /// The Lightning balance auto-conversion actually waits for: the higher of "Convert above" and
  /// the protocol minimum. Only set when activating.
  final String? effectiveThreshold;
}

abstract class HomeSettingsViewModelBase with Store {
  HomeSettingsViewModelBase(this._settingsStore, this._balanceViewModel)
      : tokens = ObservableSet<CryptoCurrency>(),
        isAddingToken = false,
        isDeletingToken = false,
        isValidatingContractAddress = false,
        showCombinedBalance = _balanceViewModel.wallet.walletInfo.showCombinedBalance,
        favoriteToken = _balanceViewModel.wallet.currency {
    final wallet = _balanceViewModel.wallet;
    thresholdSats = bitcoin?.getStableBalanceThresholdSats(wallet);
    selectedMaxSlippageBps =
        bitcoin?.getStableBalanceMaxSlippageBps(wallet) ?? selectedMaxSlippageBps;
    _updateTokensList();
    _updateLocalFavoriteToken();
    _updateBtcUsdPrice();

    // React to wallet changes
    reaction((_) => _balanceViewModel.wallet, (_) {
      _updateTokensList();
    });
    reaction((_) {
      final wallet = _balanceViewModel.wallet;
      if (isEVMCompatibleChain(wallet.type)) {
        final selectedChainId = evm!.getSelectedChainId(wallet);
        final erc20Currencies = evm!.getERC20Currencies(wallet);
        return '${wallet.currency.title}_${selectedChainId}_${erc20Currencies.length}';
      }
      return null;
    }, (_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      _updateTokensList();
    });
  }

  final SettingsStore _settingsStore;
  final BalanceViewModel _balanceViewModel;

  /// Exposed so a screen already holding a [HomeSettingsViewModel] instance (e.g.
  /// `home_settings_page.dart`) can navigate to another wallet-scoped screen (e.g. Spark
  /// settings) that's constructed the same way, from a [BalanceViewModel], via DI.
  BalanceViewModel get balanceViewModel => _balanceViewModel;

  final ObservableSet<CryptoCurrency> tokens;

  @computed
  List<CryptoCurrency> get enabledTokens =>
      [_balanceViewModel.wallet.currency, ...tokens.where((item) => item.enabled).toList()];

  WalletType get walletType => _balanceViewModel.wallet.type;

  bool get _isSparkTokenWallet =>
      FeatureFlag.isSparkTokensEnabled &&
      _balanceViewModel.wallet.type == WalletType.bitcoin &&
      _balanceViewModel.wallet.hasLightningSupport;

  /// Same gate as [_isSparkTokenWallet] - the toggle only makes sense for a wallet that can hold
  /// a stablecoin Spark token in the first place.
  bool get showStableBalanceToggle => _isSparkTokenWallet;

  /// Delegates to [BalanceViewModel] - shared with the home-screen balance card, so both read
  /// the same real state instead of keeping their own, potentially-inconsistent copies.
  bool get stableBalanceActive => _balanceViewModel.stableBalanceActive;

  /// The symbol of the first enabled Spark token tagged as a stablecoin (USDB today), used as
  /// the `StableBalanceToken.label` to activate. Generic on purpose, not hardcoded to USDB - see
  /// `LightningWallet.stableBalanceTokensFrom` for the matching connect-time registration.
  String? get _firstStableBalanceLabel => _stableBalanceToken?.title;

  CryptoCurrency? get _stableBalanceToken =>
      (bitcoin?.getSparkTokenCurrencies(_balanceViewModel.wallet) ?? const <CryptoCurrency>[])
          .firstWhereOrNull((token) => token.groups.contains(CurrencyGroups.stablecoin));

  /// The same lookup, exposed for Stable Balance settings' toggle subtitle ("Incoming BTC
  /// auto-converts to ${token}") - see [_firstStableBalanceLabel]'s doc comment. Named without
  /// the leading underscore since it's read from outside this class, unlike the private helper.
  String? get stableBalanceTokenLabel => _firstStableBalanceLabel;

  /// The available slippage presets, in basis points (50 = 0.5%). Chosen by the user before
  /// confirming activation - see [setStableBalanceActive]'s `maxSlippageBps` param.
  static const List<int> maxSlippagePresetsBps = [50, 100, 200, 500];

  /// Kept in sync with `LightningWallet.defaultMaxSlippageBps`, which the SDK connects with.
  static const int defaultMaxSlippageBps = 100;

  @observable
  int selectedMaxSlippageBps = defaultMaxSlippageBps;

  String slippageLabel(int bps) => "${(bps / 100).toStringAsFixed(1)}%";

  /// The minimum sats balance that must accumulate before an automatic BTC-to-stablecoin
  /// conversion fires - the SDK's `thresholdSats`. Left `null` (the recommended default, per
  /// https://sdk-doc-spark.breez.technology/guide/config.html#stable-balance-configuration) to
  /// use the protocol's own conversion minimum instead of a fixed value; the SDK falls back to
  /// that same minimum anyway if a configured value here is below it.
  @observable
  BigInt? thresholdSats;

  /// BTC's price in USD specifically - NOT [SettingsStore.fiatCurrency]'s price, which is
  /// whatever the wallet's display currency happens to be. Stable Balance always converts to a
  /// USD-pegged stablecoin (USDB), so "Convert above" must be denominated in real USD regardless
  /// of display currency, or the trigger point would silently drift in USD terms every time the
  /// display currency moves against the dollar. Fetched once in the constructor, refreshed via
  /// [_updateBtcUsdPrice].
  @observable
  double? _btcUsdPrice;

  Future<void> _updateBtcUsdPrice() async {
    try {
      _btcUsdPrice = await FiatConversionService.fetchPrice(
          crypto: CryptoCurrency.btc,
          fiat: FiatCurrency.usd,
          torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly);
    } catch (_) {}
  }

  /// [thresholdSats] formatted as its USD-equivalent amount ("5.00"), or `null` when there's no
  /// threshold set (Automatic) or the BTC/USD price hasn't loaded yet.
  String? get thresholdFiatAmount {
    final sats = thresholdSats;
    final price = _btcUsdPrice;
    if (sats == null || price == null) return null;
    final btcAmount = Money(sats, CryptoCurrency.btc).toStringWithPrecision();
    return calculateFiatAmount(price: price, cryptoAmount: btcAmount, raw: true);
  }

  /// [thresholdFiatAmount] with a "$" prefix, falling back to a raw sats label instead of
  /// misleadingly reading as Automatic when the BTC/USD price hasn't loaded yet.
  String? get thresholdDisplayLabel {
    final sats = thresholdSats;
    if (sats == null) return null;
    final fiat = thresholdFiatAmount;
    return fiat != null ? "\$$fiat" : "$sats sats";
  }

  String _formatSats(BigInt sats) =>
      Money(sats, CryptoCurrency.btcln).toStringWithSymbol(useBaseUnit: true);

  String _satsInUsd(BigInt sats, double btcUsdPrice) {
    final btc = Money(sats, CryptoCurrency.btc).toStringWithPrecision();
    return "\$${calculateFiatAmount(price: btcUsdPrice, cryptoAmount: btc, raw: true)}";
  }

  Money _heldBalance(CryptoCurrency currency) =>
      _balanceViewModel.wallet.balance[currency]?.available ?? Money.zero(currency);

  /// Mirrors the SDK's activation rules: the whole Lightning sats balance converts once it
  /// reaches max(thresholdSats, protocol minimum), unless the USDB it would produce is still below
  /// the minimum to ever convert back (the SDK skips that as dust).
  Future<StableBalanceConversionPreview> previewActivation() async {
    final token = _stableBalanceToken;
    final price = _btcUsdPrice;
    if (token == null || price == null) return StableBalanceConversionPreview.unknown;

    final SparkConversionLimits? limits;
    final SparkConversionLimits? reverseLimits;
    try {
      limits = await bitcoin?.fetchStableConversionLimits(_balanceViewModel.wallet, token);
      reverseLimits =
          await bitcoin?.fetchReverseStableConversionLimits(_balanceViewModel.wallet, token);
    } catch (e) {
      printV("StableBalance: failed to fetch conversion limits: $e");
      return StableBalanceConversionPreview.unknown;
    }
    if (limits == null || reverseLimits == null) return StableBalanceConversionPreview.unknown;

    final minIn = limits.minAmountIn?.amount ?? BigInt.zero;
    final configured = thresholdSats ?? BigInt.zero;
    final threshold = configured > minIn ? configured : minIn;
    final effectiveThreshold = _satsInUsd(threshold, price);

    final sats = _heldBalance(CryptoCurrency.btcln).amount;
    if (sats == BigInt.zero) {
      return StableBalanceConversionPreview(
        StableBalanceConversionOutcome.nothingToConvert,
        effectiveThreshold: effectiveThreshold,
      );
    }
    if (sats < threshold) {
      return StableBalanceConversionPreview(
        StableBalanceConversionOutcome.belowMinimum,
        amount: _formatSats(sats),
        minimum: _formatSats(threshold),
        effectiveThreshold: effectiveThreshold,
      );
    }

    final tokenMin = reverseLimits.minAmountOut;
    if (tokenMin != null) {
      final heldUsd = double.parse(_heldBalance(token).toString());
      final minUsd = double.parse(tokenMin.toString());
      final estimatedUsd = double.parse(Money(sats, CryptoCurrency.btc).toString()) * price;
      if (heldUsd < minUsd && heldUsd + estimatedUsd < minUsd) {
        final minSats = BigInt.from(((minUsd - heldUsd) / price * 1e8).ceil());
        return StableBalanceConversionPreview(
          StableBalanceConversionOutcome.belowMinimum,
          amount: _formatSats(sats),
          minimum: _formatSats(minSats),
          effectiveThreshold: effectiveThreshold,
        );
      }
    }

    return StableBalanceConversionPreview(
      StableBalanceConversionOutcome.willConvert,
      amount: _formatSats(sats),
      estimate: _satsInUsd(sats, price),
      effectiveThreshold: effectiveThreshold,
    );
  }

  /// Mirrors the SDK's deactivation rules: the whole token balance converts back to sats unless
  /// it's below the protocol minimum for a token -> Bitcoin conversion.
  Future<StableBalanceConversionPreview> previewDeactivation() async {
    final token = _stableBalanceToken;
    if (token == null) return StableBalanceConversionPreview.unknown;

    final held = _heldBalance(token);
    if (held.amount == BigInt.zero) {
      return const StableBalanceConversionPreview(StableBalanceConversionOutcome.nothingToConvert);
    }

    final SparkConversionLimits? reverseLimits;
    try {
      reverseLimits =
          await bitcoin?.fetchReverseStableConversionLimits(_balanceViewModel.wallet, token);
    } catch (e) {
      printV("StableBalance: failed to fetch reverse conversion limits: $e");
      return StableBalanceConversionPreview.unknown;
    }
    if (reverseLimits == null) return StableBalanceConversionPreview.unknown;

    final tokenMin = reverseLimits.minAmountOut;
    if (tokenMin != null && held.amount < tokenMin.amount) {
      return StableBalanceConversionPreview(
        StableBalanceConversionOutcome.belowMinimum,
        amount: held.toStringWithSymbol(),
        minimum: tokenMin.toStringWithSymbol(),
      );
    }

    final price = _btcUsdPrice;
    return StableBalanceConversionPreview(
      StableBalanceConversionOutcome.willConvert,
      amount: held.toStringWithSymbol(),
      estimate: price == null
          ? null
          : _formatSats(BigInt.from((double.parse(held.toString()) / price * 1e8).round())),
    );
  }

  /// Converts a dollar string (e.g. "5.00", as typed into Spark Settings' "Convert above" field)
  /// into [thresholdSats]. Blank input clears it to `null` (Automatic); unparsable input or no
  /// BTC/USD price yet leaves the previous value alone rather than silently discarding it.
  @action
  void setThresholdSatsFromFiat(String fiatAmount) {
    final trimmed = fiatAmount.trim();
    if (trimmed.isEmpty) {
      thresholdSats = null;
      return;
    }
    final usd = double.tryParse(trimmed.replaceAll(",", "."));
    if (usd == null) return;
    final price = _btcUsdPrice;
    if (price == null || price <= 0) return;
    // Round to BTC decimals first; Money.tryParse rejects a fraction longer than that.
    final btcAmount = (usd / price).toStringAsFixed(CryptoCurrency.btc.decimals);
    thresholdSats = Money.tryParse(btcAmount, CryptoCurrency.btc)?.amount;
  }

  /// True while a [setStableBalanceActive] call is in flight - turning Stable Balance ON, or
  /// changing [selectedMaxSlippageBps]/[thresholdSats] while it's already on, forces a full Breez
  /// SDK disconnect+reconnect (see `LightningWallet.reconnectWithStableBalanceSettings`), which is
  /// a real network round-trip, not instant. The toggle row shows a "thinking" state and ignores
  /// further taps for the duration rather than looking unresponsive or racing itself.
  @observable
  bool isTogglingStableBalance = false;

  /// Non-null while a reconnect specifically triggered by editing that setting (as opposed to the
  /// on/off toggle itself) is in flight - lets Spark Settings show "Applying - reconnecting
  /// Lightning..." on just that one row instead of the whole page.
  @observable
  StableBalanceSetting? applyingSetting;

  /// Non-null when the last attempt to apply that setting failed and was reverted - drives Spark
  /// Settings' failure banner. Cleared at the start of every new [setStableBalanceActive] call.
  @observable
  StableBalanceSetting? failedSetting;

  /// The value [failedSetting] was reverted back to, formatted for the failure banner headline
  /// ("Couldn't apply - reverted to ${this}") - read *after* the revert, so this is simply
  /// whatever the field's own display getter currently says.
  String? get failedSettingRevertedToLabel {
    switch (failedSetting) {
      case StableBalanceSetting.maxSlippage:
        return slippageLabel(selectedMaxSlippageBps);
      case StableBalanceSetting.thresholdSats:
        return thresholdDisplayLabel;
      case null:
        return null;
    }
  }

  void _revertSetting(
      StableBalanceSetting setting, int? previousMaxSlippageBps, BigInt? previousThresholdSats) {
    switch (setting) {
      case StableBalanceSetting.maxSlippage:
        if (previousMaxSlippageBps != null) selectedMaxSlippageBps = previousMaxSlippageBps;
        break;
      case StableBalanceSetting.thresholdSats:
        thresholdSats = previousThresholdSats;
        break;
    }
    failedSetting = setting;
  }

  /// Turning Stable Balance OFF is instant, no slippage involved. Turning it ON requires
  /// [maxSlippageBps] - callers must confirm with the user first (a reconnect with a new
  /// slippage value is not instant/free, per ticket 09's design) - see
  /// `spark_settings.dart`'s confirmation dialog, which is the only caller that should ever pass
  /// `true` with no [triggeredBy]. [thresholdSats] is read from the [thresholdSats] observable
  /// directly rather than taken as a param, since - unlike slippage - Spark Settings lets it be
  /// edited independently of the on/off toggle (see [applyNewMaxSlippage]/[applyNewThresholdFromFiat]).
  /// [triggeredBy]/[previousMaxSlippageBps]/[previousThresholdSats] are set only when a
  /// slippage/threshold edit (not the toggle itself) is what triggered this reconnect, so a
  /// failure can be reverted and reported on just that row.
  @action
  Future<void> setStableBalanceActive(
    bool value, {
    int? maxSlippageBps,
    StableBalanceSetting? triggeredBy,
    int? previousMaxSlippageBps,
    BigInt? previousThresholdSats,
  }) async {
    printV("StableBalance: setStableBalanceActive($value, maxSlippageBps=$maxSlippageBps, "
        "thresholdSats=$thresholdSats) called, _isSparkTokenWallet=$_isSparkTokenWallet, "
        "bitcoin==null: ${bitcoin == null}");
    if (!_isSparkTokenWallet || isTogglingStableBalance) return;
    isTogglingStableBalance = true;
    applyingSetting = triggeredBy;
    failedSetting = null;
    try {
      if (value) {
        printV("StableBalance: reconnecting with maxSlippageBps=$maxSlippageBps, "
            "thresholdSats=$thresholdSats");
        final reconnected = await bitcoin?.reconnectStableBalanceSettings(
          _balanceViewModel.wallet,
          maxSlippageBps: maxSlippageBps,
          thresholdSats: thresholdSats,
        );
        printV("StableBalance: reconnect returned $reconnected");
        if (reconnected != true) {
          if (triggeredBy != null) {
            _revertSetting(triggeredBy, previousMaxSlippageBps, previousThresholdSats);
          }
          return;
        }
        // The next cold start reconnects from these saved values, not from this session's.
        _persistStableBalanceSettings();
      }
      final label = value ? _firstStableBalanceLabel : null;
      printV("StableBalance: resolved label=$label, calling bitcoin.setStableBalanceActive");
      await bitcoin?.setStableBalanceActive(_balanceViewModel.wallet, label);
      printV("StableBalance: bitcoin.setStableBalanceActive returned successfully");
    } catch (e) {
      // The SDK throws "Stable balance is not configured" when the *current* Breez session
      // connected before this wallet had any stablecoin token registered - a stale-session
      // problem, not a real failure. Fail soft below either way: re-read the real state rather
      // than trusting `value` blindly, whether this succeeded or not.
      printV("StableBalance: failed to set active: $e");
      if (triggeredBy != null) {
        _revertSetting(triggeredBy, previousMaxSlippageBps, previousThresholdSats);
      }
    } finally {
      await _balanceViewModel.refreshStableBalanceActive();
      isTogglingStableBalance = false;
      applyingSetting = null;
    }
  }

  /// [maxSlippageBps] only takes effect at connect time (see
  /// `LightningWallet.reconnectWithStableBalanceSettings`), so editing it from Spark Settings
  /// while Stable Balance is already on requires a reconnect to actually apply. A no-op while
  /// it's off - the new value simply takes effect the next time it's turned on. On a failed
  /// reconnect, reverts to the previous value and reports it via [failedSetting].
  @action
  Future<void> applyNewMaxSlippage(int bps) async {
    final previous = selectedMaxSlippageBps;
    if (bps == previous) return;
    selectedMaxSlippageBps = bps;
    _persistStableBalanceSettings();
    if (!stableBalanceActive) return;
    await setStableBalanceActive(
      true,
      maxSlippageBps: bps,
      triggeredBy: StableBalanceSetting.maxSlippage,
      previousMaxSlippageBps: previous,
    );
    _persistStableBalanceSettings();
  }

  /// Same as [applyNewMaxSlippage], for the "Convert above" threshold - see [setThresholdSatsFromFiat].
  @action
  Future<void> applyNewThresholdFromFiat(String fiatAmount) async {
    final previous = thresholdSats;
    setThresholdSatsFromFiat(fiatAmount);
    if (thresholdSats == previous) return;
    _persistStableBalanceSettings();
    if (!stableBalanceActive) return;
    await setStableBalanceActive(
      true,
      maxSlippageBps: selectedMaxSlippageBps,
      triggeredBy: StableBalanceSetting.thresholdSats,
      previousThresholdSats: previous,
    );
    _persistStableBalanceSettings();
  }

  /// Persists [thresholdSats]/[selectedMaxSlippageBps] so they survive navigating away from Spark Settings.
  void _persistStableBalanceSettings() {
    unawaited(bitcoin?.saveStableBalanceSettings(
      _balanceViewModel.wallet,
      thresholdSats: thresholdSats,
      maxSlippageBps: selectedMaxSlippageBps,
    ));
  }

  @observable
  bool isAddingToken;

  @observable
  bool isDeletingToken;

  @observable
  bool isValidatingContractAddress;

  @observable
  String searchText = '';

  @computed
  SortBalanceBy get sortBalanceBy => _settingsStore.sortBalanceBy;

  @action
  void setSortBalanceBy(SortBalanceBy value) {
    _settingsStore.sortBalanceBy = value;
    _updateTokensList();
  }

  @computed
  bool get pinNativeToken => _settingsStore.pinNativeTokenAtTop;

  @action
  void setPinNativeToken(bool value) => _settingsStore.pinNativeTokenAtTop = value;

  @action
  Future<void> addToken({
    required String contractAddress,
    required CryptoCurrency token,
  }) async {
    try {
      isAddingToken = true;

      if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
        final evmToken = Erc20Token(
          name: token.name,
          symbol: token.title,
          decimal: token.decimals,
          contractAddress: contractAddress.toLowerCase(),
          iconPath: token.iconPath,
          isPotentialScam: token.isPotentialScam,
        );
        await evm!.addErc20Token(_balanceViewModel.wallet, evmToken);
      }

      if (_balanceViewModel.wallet.type == WalletType.solana) {
        final splToken = token.copyWith(enabled: true);
        await solana!.addSPLToken(
          _balanceViewModel.wallet,
          splToken,
          contractAddress,
        );
      }

      if (_balanceViewModel.wallet.type == WalletType.tron) {
        final tronToken = token.copyWith(enabled: true);
        await tron!.addTronToken(_balanceViewModel.wallet, tronToken, contractAddress);
      }

      if (_balanceViewModel.wallet.type == WalletType.zano) {
        await zano!.addZanoAssetById(_balanceViewModel.wallet, contractAddress);
      }

      if (_isSparkTokenWallet) {
        final sparkToken = bitcoin!.createSparkToken(
          name: token.name,
          symbol: token.title,
          decimals: token.decimals,
          tokenIdentifier: contractAddress,
          iconPath: token.iconPath,
          isPotentialScam: token.isPotentialScam,
        );
        await bitcoin!.addSparkToken(_balanceViewModel.wallet, sparkToken);
      }

      _updateTokensList();
      _updateFiatPrices(token);
    } catch (e) {
      throw e;
    } finally {
      isAddingToken = false;
    }
  }

  @action
  bool checkIfTokenIsAlreadyAdded(String contractAddress) {
    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      return evm!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      return solana!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.tron) {
      return tron!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      return zano!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_isSparkTokenWallet) {
      return bitcoin!.isSparkTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    return false;
  }

  @action
  Future<void> deleteToken(CryptoCurrency token) async {
    try {
      isDeletingToken = true;
      if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
        await evm!.deleteErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      }

      if (_balanceViewModel.wallet.type == WalletType.solana) {
        await solana!.deleteSPLToken(_balanceViewModel.wallet, token);
      }

      if (_balanceViewModel.wallet.type == WalletType.tron) {
        await tron!.deleteTronToken(_balanceViewModel.wallet, token);
      }
      if (_balanceViewModel.wallet.type == WalletType.zano) {
        await zano!.deleteZanoAsset(_balanceViewModel.wallet, token);
      }
      if (_isSparkTokenWallet) {
        await bitcoin!.deleteSparkToken(_balanceViewModel.wallet, token);
      }
      _updateTokensList();
    } finally {
      isDeletingToken = false;
    }
  }

  Future<bool> checkIfERC20TokenContractAddressIsAPotentialScamAddress(
    String contractAddress,
  ) async {
    try {
      isValidatingContractAddress = true;

      if (!isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
        return false;
      }

      bool isPotentialScamViaMoralis = await _isPotentialScamTokenViaMoralis(
        contractAddress,
        getChainNameBasedOnWalletType(_balanceViewModel.wallet.type),
      );

      bool isUnverifiedContract = await _isContractUnverified(
        contractAddress,
        chainId: evm!.getSelectedChainId(_balanceViewModel.wallet).toString(),
      );

      final showWarningForContractAddress = isPotentialScamViaMoralis || isUnverifiedContract;

      return showWarningForContractAddress;
    } finally {
      isValidatingContractAddress = false;
    }
  }

  bool checkIfTokenIsWhitelisted(String contractAddress) {
    // get the default tokens for each currency type:
    List<String> defaultTokenAddresses = [];
    switch (_balanceViewModel.wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        defaultTokenAddresses = evm!.getDefaultTokenContractAddresses(_balanceViewModel.wallet);
        break;
      case WalletType.solana:
        defaultTokenAddresses = solana!.getDefaultTokenContractAddresses();
        break;
      case WalletType.tron:
        defaultTokenAddresses = tron!.getDefaultTokenContractAddresses();
        break;
      case WalletType.zano:
      case WalletType.banano:
      case WalletType.monero:
      case WalletType.none:
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.haven:
      case WalletType.nano:
      case WalletType.wownero:
      case WalletType.bitcoinCash:
      case WalletType.decred:
      case WalletType.dogecoin:
      case WalletType.zcash:
        return false;
    }

    // check if the contractAddress is in the defaultTokenAddresses
    bool isInWhitelist = defaultTokenAddresses
        .any((element) => element.toLowerCase() == contractAddress.toLowerCase());
    return isInWhitelist;
  }

  bool checkIfTokenSymbolMatchesDefaultToken(String symbol) {
    final normalizedSymbol = normalizeHomoglyphs(symbol.trim().toUpperCase());
    if (normalizedSymbol.isEmpty) return false;

    List<String> defaultTokenSymbols = [];
    switch (_balanceViewModel.wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        defaultTokenSymbols = evm!.getDefaultTokenSymbols(_balanceViewModel.wallet);
        break;
      case WalletType.solana:
        defaultTokenSymbols = solana!.getDefaultTokenSymbols();
        break;
      case WalletType.tron:
        defaultTokenSymbols = tron!.getDefaultTokenSymbols();
        break;
      case WalletType.zano:
      case WalletType.banano:
      case WalletType.monero:
      case WalletType.none:
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.haven:
      case WalletType.nano:
      case WalletType.wownero:
      case WalletType.bitcoinCash:
      case WalletType.decred:
      case WalletType.dogecoin:
      case WalletType.zcash:
        return false;
    }

    return defaultTokenSymbols.any((s) => s.toUpperCase() == normalizedSymbol);
  }

  Future<bool> _isPotentialScamTokenViaMoralis(
    String contractAddress,
    String chainName,
  ) async {
    final uri = Uri.https(
      'deep-index.moralis.io',
      '/api/v2.2/erc20/metadata',
      {
        "chain": chainName,
        "addresses": contractAddress,
      },
    );

    try {
      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: {
          "Accept": "application/json",
          "X-API-Key": secrets.moralisApiKey,
        },
      );

      final decodedResponse = jsonDecode(response.body);

      final tokenInfo = Erc20TokenInfoMoralis.fromJson(decodedResponse[0] as Map<String, dynamic>);

      // Based on analysis using Moralis internal metrics
      if (tokenInfo.possibleSpam == true) {
        return true;
      }

      // Tokens whose contract have not been verified are potentially risky tokens.
      // if (tokenInfo.verifiedContract == false) {
      //   return true;
      // }

      // Tokens with a security score less than 40 are potentially risky, requiring caution when dealing with them.
      if (tokenInfo.securityScore != null && tokenInfo.securityScore! < 40) {
        return true;
      }

      // Having a Fully Diluted Valiuation of 0 is a significant red flag that could signify:
      // - An abandoned/unlaunched project
      // - Incorrect/missing token data
      // - Suspicious manipulation of token data

      /// commented out as it's failing a lot of legit tokens
      // if (tokenInfo.fullyDilutedValuation == '0') {
      //   return true;
      // }

      return false;
    } catch (e) {
      printV('Error while checking scam via moralis: ${e.toString()}');
      return true;
    }
  }

  Future<bool> _isContractUnverified(
    String contractAddress, {
    required String chainId,
  }) async {
    final uri = Uri.https(
      "api.etherscan.io",
      "/v2/api",
      {
        "chainid": chainId,
        "module": "contract",
        "action": "getsourcecode",
        "address": contractAddress,
        "apikey": secrets.etherScanApiKey,
      },
    );

    try {
      final response = await ProxyWrapper().get(clearnetUri: uri);

      final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (decodedResponse['status'] == '0') {
        printV('${response.body}\n');
        printV('${decodedResponse['result']}\n');
        return true;
      }

      if (decodedResponse['status'] == '1' &&
          decodedResponse['result'][0]['ABI'] == 'Contract source code not verified') {
        printV('Call is valid but contract is not verified');
        return true; // Contract is not verified
      } else {
        printV('Call is valid and contract is verified');
        return false; // Contract is verified
      }
    } catch (e) {
      printV('Error while checking contract verification: ${e.toString()}');
      return true;
    }
  }

  Future<CryptoCurrency?> getToken(String contractAddress) async {
    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      return await evm!.getErc20Token(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      return await solana!.getSPLToken(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.tron) {
      return await tron!.getTronToken(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      return await zano!.getZanoAsset(_balanceViewModel.wallet, contractAddress);
    }

    if (_isSparkTokenWallet) {
      return await bitcoin!.getSparkToken(_balanceViewModel.wallet, contractAddress);
    }

    return null;
  }

  Future<bool?> checkIfTokenIsVerifiedOnJupiter(String mintAddress) async {
    if (_balanceViewModel.wallet.type != WalletType.solana) {
      return null;
    }

    return solana!.isTokenVerifiedOnJupiter(_balanceViewModel.wallet, mintAddress);
  }

  CryptoCurrency get nativeToken => _balanceViewModel.wallet.currency;

  void _updateFiatPrices(CryptoCurrency token) async {
    if (token.isPotentialScam) return; // don't fetch price data for potential scam tokens
    try {
      _balanceViewModel.fiatConversionStore.prices[token] = await FiatConversionService.fetchPrice(
          crypto: token,
          fiat: _settingsStore.fiatCurrency,
          torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly);
    } catch (_) {}
  }

  void changeTokenAvailability(CryptoCurrency token, bool value) async {
    token.enabled = value;

    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      evm!.addErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      if (!value) evm!.removeTokenTransactionsInHistory(_balanceViewModel.wallet, token);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      final address = solana!.getTokenAddress(token);
      solana!.addSPLToken(_balanceViewModel.wallet, token, address);
    }

    if (_balanceViewModel.wallet.type == WalletType.tron) {
      final address = tron!.getTokenAddress(token);
      tron!.addTronToken(_balanceViewModel.wallet, token, address);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      await zano!.changeZanoAssetAvailability(_balanceViewModel.wallet, token);
    }

    if (_isSparkTokenWallet) {
      bitcoin!.addSparkToken(_balanceViewModel.wallet, token);
    }

    _refreshTokensList();
  }

  @action
  void _updateTokensList() {
    int _sortFunc(CryptoCurrency e1, CryptoCurrency e2) {
      int index1 = _balanceViewModel.formattedBalances.indexWhere((element) => element.asset == e1);
      int index2 = _balanceViewModel.formattedBalances.indexWhere((element) => element.asset == e2);

      if (e1.enabled && !e2.enabled) {
        return -1;
      } else if (e2.enabled && !e1.enabled) {
        return 1;
      } else if (!e1.enabled && !e2.enabled) {
        // if both are disabled then sort alphabetically
        return e1.name.compareTo(e2.name);
      }

      return index1.compareTo(index2);
    }

    tokens.clear();

    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      tokens.addAll(evm!
          .getERC20Currencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      tokens.addAll(solana!
          .getSPLTokenCurrencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_balanceViewModel.wallet.type == WalletType.tron) {
      tokens.addAll(tron!
          .getTronTokenCurrencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      tokens.addAll(zano!
          .getZanoAssets(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_isSparkTokenWallet) {
      tokens.addAll(bitcoin!
          .getSparkTokenCurrencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }
  }

  // FIXME these two observables cause duplicated state and are needed because mobx. remove them as part of the refactor and replace with proper getters
  @observable
  bool showCombinedBalance;

  @observable
  CryptoCurrency favoriteToken;

  @action
  void setShowCombinedBalance(bool value) {
    _balanceViewModel.wallet.walletInfo.showCombinedBalance = value;
    showCombinedBalance = value;
    _balanceViewModel.wallet.updateBalance();
    _balanceViewModel.wallet.walletInfo.save();
  }

  @action
  Future<void> setFavoriteToken(CryptoCurrency token) async {
    final String? address;

    if (token == _balanceViewModel.wallet.currency) {
      address = null;
    } else {
      address = getTokenAddressBasedOnWallet(token);
    }

    _balanceViewModel.wallet.walletInfo.favoriteTokenAddress = address;
    _balanceViewModel.wallet.walletInfo.save();
    _updateLocalFavoriteToken();
  }

  @action
  Future<void> _updateLocalFavoriteToken() async {
    favoriteToken = await TokenUtilities.findTokenByAddress(
            walletType: _balanceViewModel.wallet.type,
            address: _balanceViewModel.wallet.walletInfo.favoriteTokenAddress ?? "") ??
        _balanceViewModel.wallet.currency;
  }

  @action
  void _refreshTokensList() {
    final _tokens = Set.of(tokens);
    tokens.clear();
    tokens.addAll(_tokens);
  }

  @action
  void changeSearchText(String text) {
    searchText = text;
    _updateTokensList();
  }

  bool _matchesSearchText(CryptoCurrency asset) {
    final address = getTokenAddressBasedOnWallet(asset);

    // A null address means this wallet type isn't one of the token-bearing types this screen
    // supports (Tron/EVM/Solana/Zano/Spark) - filter it out rather than showing an addressless row.
    if (address == null) return false;

    return searchText.isEmpty ||
        asset.fullName!.toLowerCase().contains(searchText.toLowerCase()) ||
        asset.title.toLowerCase().contains(searchText.toLowerCase()) ||
        address == searchText;
  }

  String? getTokenAddressBasedOnWallet(CryptoCurrency asset) {
    if (_balanceViewModel.wallet.type == WalletType.tron) {
      return tron!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      return solana!.getTokenAddress(asset);
    }

    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      return evm!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      return zano!.getZanoAssetAddress(asset);
    }

    if (_isSparkTokenWallet) {
      final sparkTokenIdentifier = bitcoin?.getSparkTokenIdentifier(asset);
      if (sparkTokenIdentifier != null) return sparkTokenIdentifier;
    }

    // We return null if it's neither Tron, EVM, Solana, Zano, nor a Spark-token Bitcoin wallet
    // (which is actually impossible because we only display home settings for those wallets).
    return null;
  }
}
