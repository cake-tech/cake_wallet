import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'balance_view_model.g.dart';

class BalanceRecord {
  const BalanceRecord({
    required this.raw,
    required this.availableBalance,
    required this.additionalBalance,
    required this.secondAvailableBalance,
    required this.secondAdditionalBalance,
    required this.frozenBalance,
    required this.fiatAvailableBalanceRaw,
    required this.fiatAdditionalBalanceRaw,
    required this.fiatFrozenBalanceRaw,
    required this.fiatSecondAvailableBalanceRaw,
    required this.fiatSecondAdditionalBalanceRaw,
    required this.asset,
    required this.secondAsset,
    required this.fiatCurrency,
    required this.formattedAssetTitle,
    this.languageCode,
  });

  final Balance raw;

  final String fiatAvailableBalanceRaw;
  final String fiatAdditionalBalanceRaw;
  final String fiatFrozenBalanceRaw;
  final String fiatSecondAvailableBalanceRaw;
  final String fiatSecondAdditionalBalanceRaw;

  final String additionalBalance;
  final String availableBalance;
  final String frozenBalance;
  final String secondAvailableBalance;
  final String secondAdditionalBalance;
  final CryptoCurrency asset;
  final CryptoCurrency secondAsset;
  final FiatCurrency? fiatCurrency;
  final String formattedAssetTitle;
  final String? languageCode;

  String get combinedAvailableBalance =>
      (raw.available + (raw.secondAvailable ?? Money.zero(raw.available.currency)))
          .toString()
          .withMaxDecimals(8);

  String get combinedFiatAvailableBalance => fiatCurrency != null
      ? "$fiatCurrency " +
          _withLocalSeperator(((double.tryParse(fiatAvailableBalanceRaw) ?? 0) +
                  (double.tryParse(fiatSecondAvailableBalanceRaw) ?? 0))
              .toStringAsFixed(2))
      : "";

  String get fiatAvailableBalance =>
      fiatCurrency != null ? "$fiatCurrency ${_withLocalSeperator(fiatAvailableBalanceRaw)}" : "";

  String get fiatAdditionalBalance =>
      fiatCurrency != null ? "$fiatCurrency ${_withLocalSeperator(fiatAdditionalBalanceRaw)}" : "";

  String get fiatFrozenBalance =>
      fiatCurrency != null ? "$fiatCurrency ${_withLocalSeperator(fiatFrozenBalanceRaw)}" : "";

  String get fiatSecondAvailableBalance => fiatCurrency != null
      ? "$fiatCurrency ${_withLocalSeperator(fiatSecondAvailableBalanceRaw)}"
      : "";

  String get fiatSecondAdditionalBalance => fiatCurrency != null
      ? "$fiatCurrency ${_withLocalSeperator(fiatSecondAdditionalBalanceRaw)}"
      : "";

  String _withLocalSeperator(String rawAmount) =>
      languageCode == null ? rawAmount : rawAmount.withLocalSeperator(languageCode);
}

class BalanceViewModel = BalanceViewModelBase with _$BalanceViewModel;

abstract class BalanceViewModelBase with Store {
  BalanceViewModelBase(
      {required this.appStore, required this.settingsStore, required this.fiatConversionStore})
      : isReversing = false,
        isShowCard = appStore.wallet?.walletInfo.isShowIntroCakePayCard ?? false,
        wallet = appStore.wallet! {
    reaction((_) => appStore.wallet, (wallet) {
      _onWalletChange(wallet);
      _checkMweb();
    });

    _checkMweb();

    reaction((_) => settingsStore.mwebAlwaysScan, (_) => _checkMweb());
  }

  void _checkMweb() {
    if (wallet.type == WalletType.litecoin) {
      mwebEnabled = bitcoin!.getMwebEnabled(wallet);
    }
  }

  final AppStore appStore;
  final SettingsStore settingsStore;
  final FiatConversionStore fiatConversionStore;

  @observable
  bool isReversing;

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet;

  @computed
  double get price {
    final price = fiatConversionStore.prices[appStore.wallet!.currency];

    // price should update on next fetch:
    if (price == null) return 0;

    return price;
  }

  @computed
  BalanceDisplayMode get savedDisplayMode => settingsStore.balanceDisplayMode;

  @computed
  bool get isFiatDisabled => settingsStore.fiatApiMode == FiatApiMode.disabled;

  @computed
  bool get isHomeScreenSettingsEnabled =>
      isEVMCompatibleChain(wallet.type) ||
      [WalletType.solana, WalletType.tron, WalletType.zano].contains(wallet.type);

  @computed
  bool get isEVMCompatible => isEVMCompatibleChain(wallet.type);

  @computed
  bool get hasAccounts => [WalletType.monero, WalletType.wownero].contains(wallet.type);

  @computed
  SortBalanceBy get sortBalanceBy => settingsStore.sortBalanceBy;

  @computed
  bool get pinNativeToken => settingsStore.pinNativeTokenAtTop;

  @computed
  String get asset {
    if (isEVMCompatibleChain(wallet.type)) {
      final currentChain = evm!.getCurrentChain(wallet);
      if (currentChain != null) {
        return currentChain.name;
      }

      return walletTypeToString(wallet.type);
    }

    final typeFormatted = walletTypeToString(wallet.type);

    switch (wallet.type) {
      case WalletType.haven:
        return '$typeFormatted Assets';
      default:
        return typeFormatted;
    }
  }

  @computed
  BalanceDisplayMode get displayMode {
    if (isReversing) {
      if (savedDisplayMode == BalanceDisplayMode.hiddenBalance) {
        return BalanceDisplayMode.displayableBalance;
      } else {
        return BalanceDisplayMode.hiddenBalance;
      }
    }

    return savedDisplayMode;
  }

  @computed
  String get availableBalanceLabel {
    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return S.current.show_balance;
    } else {
      return S.current.xmr_available_balance;
    }
  }

  @computed
  String get additionalBalanceLabel {
    switch (wallet.type) {
      case WalletType.haven:
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
      case WalletType.solana:
      case WalletType.tron:
        return S.current.xmr_full_balance;
      case WalletType.nano:
      case WalletType.banano:
        return S.current.receivable_balance;
      default:
        return S.current.unconfirmed;
    }
  }

  @computed
  String get secondAvailableBalanceLabel {
    switch (wallet.type) {
      case WalletType.litecoin:
        return S.current.mweb_confirmed;
      default:
        return S.current.confirmed;
    }
  }

  @computed
  String get secondAdditionalBalanceLabel {
    switch (wallet.type) {
      case WalletType.litecoin:
        return S.current.mweb_unconfirmed;
      default:
        return S.current.unconfirmed;
    }
  }

  Money additionalBalance(CryptoCurrency cryptoCurrency) {
    final balance = _currencyBalance(cryptoCurrency);

    if (displayMode == BalanceDisplayMode.hiddenBalance || balance.unavailable.isZero)
      return Money.zero(cryptoCurrency);

    return balance.unavailable;
  }

  @computed
  Map<CryptoCurrency, BalanceRecord> get balances {
    return wallet.balance.map((key, value) {
      var secondAsset = key == CryptoCurrency.ltc ? CryptoCurrency.ltcmweb : key;

      if (displayMode == BalanceDisplayMode.hiddenBalance) {
        final fiatCurrency = settingsStore.fiatCurrency;
        return MapEntry(
          key,
          BalanceRecord(
            raw: value,
            availableBalance: '●●●●●●',
            additionalBalance: '',
            frozenBalance: '',
            secondAvailableBalance: '●●●●●●',
            secondAdditionalBalance: '●●●●●●',
            fiatAdditionalBalanceRaw: '●●●●●',
            fiatAvailableBalanceRaw: '●●●●●',
            fiatFrozenBalanceRaw: '',
            fiatSecondAvailableBalanceRaw: '●●●●●',
            fiatSecondAdditionalBalanceRaw: '●●●●●',
            asset: key,
            secondAsset: secondAsset,
            fiatCurrency: isFiatDisabled ? null : fiatCurrency,
            formattedAssetTitle: _formatterAsset(key),
          ),
        );
      }
      final price = key.isPotentialScam
          ? 0.0
          : fiatConversionStore.prices[key == CryptoCurrency.btcln ? CryptoCurrency.btc : key] ?? 0;

      // if (price == null) {
      //   throw Exception('Price is null for: $key');
      // }

      final availableFiatBalance =
          isFiatDisabled ? '' : _getFiatBalance(price: price, cryptoAmount: value.available);

      final additionalFiatBalance =
          isFiatDisabled ? '' : _getFiatBalance(price: price, cryptoAmount: value.unavailable);

      final frozenFiatBalance =
          isFiatDisabled ? '' : _getFiatBalance(price: price, cryptoAmount: value.frozen);

      final secondAvailableFiatBalance =
          isFiatDisabled ? '' : _getFiatBalance(price: price, cryptoAmount: value.secondAvailable);

      final secondAdditionalFiatBalance = isFiatDisabled
          ? ''
          : _getFiatBalance(price: price, cryptoAmount: value.secondUnavailable);

      return MapEntry(
        key,
        BalanceRecord(
          raw: value,
          availableBalance: _getFormattedCryptoAmount(value.available),
          fiatAvailableBalanceRaw: availableFiatBalance,
          additionalBalance: _getFormattedCryptoAmount(value.unavailable),
          fiatAdditionalBalanceRaw: additionalFiatBalance,
          frozenBalance: _getFormattedCryptoAmount(value.frozen),
          fiatFrozenBalanceRaw: frozenFiatBalance,
          secondAvailableBalance: _getFormattedCryptoAmount(value.secondAvailable),
          fiatSecondAvailableBalanceRaw: secondAvailableFiatBalance,
          secondAdditionalBalance: _getFormattedCryptoAmount(value.secondUnavailable),
          fiatSecondAdditionalBalanceRaw: secondAdditionalFiatBalance,
          asset: key,
          secondAsset: secondAsset,
          fiatCurrency: isFiatDisabled ? null : settingsStore.fiatCurrency,
          formattedAssetTitle: _formatterAsset(key),
          languageCode: settingsStore.languageCode,
        ),
      );
    });
  }

  @observable
  bool mwebEnabled = false;

  bool hasAdditionalBalance(CryptoCurrency currency) {
    final isWalletTypeActivated = _hasAdditionalBalanceForWalletType(wallet.type);
    final isNotZeroAmount = !additionalBalance(currency).isZero;

    return isWalletTypeActivated && isNotZeroAmount;
  }

  @computed
  bool get hasSecondAdditionalBalance {
    if (wallet.type == WalletType.litecoin && mwebEnabled) {
      return (wallet.balance[CryptoCurrency.ltc]?.secondUnavailable ?? 0) != 0;
    } else if (wallet.type == WalletType.bitcoin) {
      return (wallet.balance[CryptoCurrency.btc]?.secondUnavailable ?? 0) != 0;
    }
    return false;
  }

  @computed
  bool get hasSecondAvailableBalance {
    switch (wallet.type) {
      case WalletType.bitcoin:
        return true;
      case WalletType.litecoin:
        return mwebEnabled;
      default:
        return false;
    }
  }

  bool _hasAdditionalBalanceForWalletType(WalletType type) => [
        WalletType.monero,
        WalletType.wownero,
        WalletType.zano,
        WalletType.decred,
        WalletType.zcash
      ].contains(type);

  String _getFormattedCryptoAmount(Money? amount) {
    if (amount == null) return "";

    return appStore.amountParsingProxy
        .asDisplayString(amount)
        .withLocalSeperator(settingsStore.languageCode);
  }

  @computed
  List<BalanceRecord> get formattedBalances {
    final balance = balances.values.toList();

    balance.sort((BalanceRecord a, BalanceRecord b) {
      if (wallet.currency == CryptoCurrency.xhv) {
        if (b.asset == CryptoCurrency.xhv) return 1;

        if (b.asset == CryptoCurrency.xusd) {
          if (a.asset == CryptoCurrency.xhv) return -1;
          return 1;
        }

        if (b.asset == CryptoCurrency.xbtc) return 1;
        if (b.asset == CryptoCurrency.xeur) return 1;

        return 0;
      }

      if (pinNativeToken) {
        if (b.asset == wallet.currency) return 1;
        if (a.asset == wallet.currency) return -1;
      }

      final isTokenWallet = isEVMCompatibleChain(wallet.type) || wallet.type == WalletType.solana;

      if (isTokenWallet) {
        final aIsToken = a.asset is Erc20Token || a.asset is SPLToken;
        final bIsToken = b.asset is Erc20Token || b.asset is SPLToken;

        final aHasBalance = (double.tryParse(a.availableBalance) ?? 0) > 0;
        final bHasBalance = (double.tryParse(b.availableBalance) ?? 0) > 0;

        // Adding this so tokens with balance come before tokens without balance
        if (aIsToken && bIsToken) {
          if (aHasBalance && !bHasBalance) return -1;
          if (!aHasBalance && bHasBalance) return 1;
        }
      }

      switch (sortBalanceBy) {
        case SortBalanceBy.FiatBalance:
          final aFiatBalance = _getFiatBalance(
              price: fiatConversionStore.prices[a.asset] ?? 0, cryptoAmount: a.raw.available);
          final bFiatBalance = _getFiatBalance(
              price: fiatConversionStore.prices[b.asset] ?? 0, cryptoAmount: b.raw.available);

          return (double.tryParse(bFiatBalance) ?? 0)
              .compareTo((double.tryParse(aFiatBalance)) ?? 0);
        case SortBalanceBy.GrossBalance:
          return (double.tryParse(b.availableBalance) ?? 0)
              .compareTo(double.tryParse(a.availableBalance) ?? 0);
        case SortBalanceBy.Alphabetical:
          return a.asset.title.compareTo(b.asset.title);
      }
    });

    return balance;
  }

  BalanceRecord? getMainBalanceRecord(bool lightningMode) {
    if (lightningMode) {
      return formattedBalances.elementAtOrNull(1);
    }

    if (wallet.walletInfo.favoriteTokenAddress != null) {
      return formattedBalances.firstWhereOrNull((item) =>
              (getTokenAddressBasedOnWallet(item.asset) ==
                  wallet.walletInfo.favoriteTokenAddress)) ??
          formattedBalances.elementAtOrNull(0);
    }

    return formattedBalances.elementAtOrNull(0);
  }

  String? getTokenAddressBasedOnWallet(CryptoCurrency asset) {
    if (wallet.type == WalletType.tron) {
      return tron!.getTokenAddress(asset);
    }

    if (wallet.type == WalletType.solana) {
      return solana!.getTokenAddress(asset);
    }

    if (isEVMCompatibleChain(wallet.type) && asset is Erc20Token) {
      return evm!.getTokenAddress(asset);
    }

    if (wallet.type == WalletType.zano) {
      return zano!.getZanoAssetAddress(asset);
    }

    return null;
  }

  @computed
  bool get showCombinedBalance {
    if (wallet.type == WalletType.bitcoin) return false;
    if (balances.values.length == 1) return false;

    return wallet.walletInfo.showCombinedBalance;
  }

  @computed
  String get combinedFiatBalance {
    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return "●●●●●";
    }

    double ret = 0.0;
    for (final curr in wallet.balance.keys) {
      final record = wallet.balance[curr]!;
      final available = record.available - (record.secondAvailable ?? Money.zero(curr));
      final price = fiatConversionStore.prices[curr] ?? 0;
      ret += double.tryParse(calculateFiatAmount(price: price, cryptoAmount: available.toString())
              .replaceAll(",", "")) ??
          0;
    }
    return ret.toStringAsFixed(2).withLocalSeperator(settingsStore.languageCode);
  }

  Balance _currencyBalance(CryptoCurrency cryptoCurrency) {
    final balance = wallet.balance[cryptoCurrency];

    if (balance == null) throw Exception('No balance for ${wallet.currency}');

    return balance;
  }

  @observable
  bool isShowCard;

  ReactionDisposer? _onCurrentWalletChangeReaction;

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>? wallet) {
    if (wallet == null) return;

    this.wallet = wallet;
    _onCurrentWalletChangeReaction?.reaction.dispose();
    isShowCard = wallet.walletInfo.isShowIntroCakePayCard;
  }

  @action
  Future<void> disableIntroCakePayCard() async {
    const cardDisplayStatus = false;
    wallet.walletInfo.showIntroCakePayCard = cardDisplayStatus;
    await wallet.walletInfo.save();
    isShowCard = cardDisplayStatus;
  }

  @action
  void switchBalanceValue() {
    if (settingsStore.balanceDisplayMode == BalanceDisplayMode.displayableBalance) {
      settingsStore.balanceDisplayMode = BalanceDisplayMode.hiddenBalance;
      settingsStore.balanceHideCounter++;
    } else {
      settingsStore.balanceDisplayMode = BalanceDisplayMode.displayableBalance;
    }
  }

  String _getFiatBalance({required double price, Money? cryptoAmount}) {
    if (cryptoAmount == null) {
      return '0.00';
    }

    return calculateFiatAmount(price: price, cryptoAmount: cryptoAmount.toString(), raw: true);
  }

  String _formatterAsset(CryptoCurrency asset) {
    final assetString = asset.toString();
    if (wallet.type == WalletType.haven &&
        asset != CryptoCurrency.xhv &&
        assetString[0].toUpperCase() == 'X') {
      return assetString.replaceFirst('X', 'x');
    }

    return appStore.amountParsingProxy.getCryptoSymbol(asset);
  }
}
