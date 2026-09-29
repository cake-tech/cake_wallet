import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/amount_parsing_proxy.dart';
import 'package:cake_wallet/core/create_trade_result.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/core/lightning_invoice_service.dart';
import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/jupiter_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/letsexchange_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/near_Intents_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_provider_preferences.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_max_amount.dart';
import 'package:collection/collection.dart' show MapEquality;
import 'package:cake_wallet/exchange/provider/stealth_ex_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swapsxyz_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swaptrade_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/xoswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';
import 'package:cw_core/amount/amount_sanitizer.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/amount/money_double.dart';
import "package:cw_core/wallet_info.dart";
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/token_utilities.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currencies_with_memo.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/tron_token.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'exchange_view_model.g.dart';

class ExchangeViewModel = ExchangeViewModelBase with _$ExchangeViewModel;

abstract class ExchangeViewModelBase extends WalletChangeListenerViewModel with Store {
  @override
  void onWalletChange(wallet) {
    // FIXME this caused a bug when switching wallet, i can't figure out why it's here?
    // receiveCurrency = wallet.currency;
    // depositCurrency = wallet.currency;
  }

  final List<ReactionDisposer> _disposers = [];

  void dispose() {
    bestRateSync.cancel();
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }

  ExchangeViewModelBase(
    this._appStore,
    this._exchangeTemplateStore,
    this.tradesStore,
    this.sharedPreferences,
    this.contactListViewModel,
    this.unspentCoinsListViewModel,
    this.feesViewModel,
    this.fiatConversionStore,
  )   : isSendAllEnabled = false,
        isFixedRateMode = false,
        isReceiveAmountEntered = false,
        _depositAmount = null,
        _receiveAmount = null,
        receiveAddress = '',
        depositAddress = '',
        isDepositAddressEnabled = false,
        isReceiveAmountEditable = false,
        _useTorOnly = false,
        receiveCurrencies = ObservableList<CryptoCurrency>(),
        depositCurrencies = ObservableList<CryptoCurrency>(),
        limits = Limits(min: 0, max: 0),
        tradeState = ExchangeTradeStateInitial(),
        limitsState = LimitsInitialState(),
        receiveCurrency = _appStore.wallet!.currency,
        depositCurrency = _appStore.wallet!.currency,
        providerList = [],
        selectedProviders = ObservableList<ExchangeProvider>(),
        super(appStore: _appStore) {
    _useTorOnly = _settingsStore.exchangeStatus == ExchangeApiMode.torOnly;
    _setProviders();
    const excludeDepositCurrencies = [CryptoCurrency.btt];
    const excludeReceiveCurrencies = [CryptoCurrency.btt];
    _initialPairBasedOnWallet();

    unspentCoinsListViewModel.initialSetup().then((_) {
      unspentCoinsListViewModel.resetUnspentCoinsInfoSelections();
    });

    final Map<String, dynamic> exchangeProvidersSelection =
        json.decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}")
            as Map<String, dynamic>;

    /// if the provider is not in the user settings (user's first time or newly added provider)
    /// then use its default value decided by us
    selectedProviders = ObservableList.of(providerList
        .where((element) =>
            (!forceDecentralizedExchanges || !element.description.isCentralized) &&
            (exchangeProvidersSelection[element.title] == null
                ? element.isEnabled
                : (exchangeProvidersSelection[element.title] as bool)))
        .toList());

    _setAvailableProviders();

    autorun((_) {
      if (selectedProviders.any((provider) => provider is TrocadorExchangeProvider)) {
        final trocadorProvider =
            selectedProviders.firstWhere((provider) => provider is TrocadorExchangeProvider)
                as TrocadorExchangeProvider;

        updateAllTrocadorProviderStates(trocadorProvider);
      }
    });

    bestRateSync = Timer.periodic(Duration(seconds: 10), (timer) {
      if (tradeState is! TradeIsCreating) {
        if (_comparisonPending == null) calculateBestRate();
        if (forcedProvider is PegaRouteExchangeProvider && _forcedPending == null) {
          calculateForcedProviderRate();
        }
      }
    });

    isDepositAddressEnabled = !useSameWalletAddress(depositCurrency);
    _depositAmount = null;
    _receiveAmount = null;
    receiveAddress = '';
    depositAddress =
        useSameWalletAddress(depositCurrency) ? wallet.walletAddresses.addressForExchange : '';

    _disposers.add(reaction((_) => receiveAddress, (_) {
      if (!(tradeState is TradeIsCreatedSuccessfully)) {
        receiveAddressDisplayName = null;
      }
    }));

    provider = providerList.firstOrNull;
    final initialProvider = provider;
    provider!.checkIsAvailable().then((bool isAvailable) {
      if (!isAvailable && provider == initialProvider) {
        provider = providerList.firstWhere((provider) => provider is ChangeNowExchangeProvider,
            orElse: () => providerList.last);
        _onPairChange();
      }
    });

    // providerDisplay is read by ui to display auto-selected provider.
    // it's on a delay so it doesn't flicker.
    _disposers.add(reaction((_) => bestRateProvider, (val) {
      providerDisplay = val;
    }, delay: 300));

    receiveCurrencies = CryptoCurrency.all
        .where((cryptoCurrency) => !excludeReceiveCurrencies.contains(cryptoCurrency))
        .toList()
        .asObservable();
    depositCurrencies = CryptoCurrency.all
        .where((cryptoCurrency) => !excludeDepositCurrencies.contains(cryptoCurrency))
        .toList()
        .asObservable();

    _injectUserEthTokensIntoCurrencyLists();
    _injectUserSplTokensIntoCurrencyLists();
    _injectUserTronTokensIntoCurrencyLists();
    _defineIsReceiveAmountEditable();
    loadLimits();
    _disposers.add(reaction((_) => isFixedRateMode, (Object _) {
      bestRateProvider = null;
      bestRate = 0.0;
      loadLimits();
    }));

    _disposers.add(reaction((_) => forceDecentralizedExchanges, (val) {
      if (val && (bestRateProvider?.description.isCentralized ?? false)) {
        bestRateProvider = null;
        bestRate = 0.0;
        loadLimits();
      }
    }));

    _disposers.add(reaction((_) => [forceDecentralizedExchanges,
      ...pegarouteProviderPreferences.states.values].join(','), (_) {
      _sortedAvailableProviders.removeWhere((rate, provider) => provider is PegaRouteExchangeProvider);
      if (bestRateProvider is PegaRouteExchangeProvider) { bestRateProvider = null; bestRate = 0; }
      if (forcedProvider is PegaRouteExchangeProvider) forcedProviderRate = 0;
      loadLimits();
      calculateBestRate();
      calculateForcedProviderRate();
    }));

    if (isElectrumWallet) {
      bitcoin!.updateFeeRates(wallet);
    }
    fetchFiatPrice(receiveCurrency);

    updateDepositAvailableAmount();
  }

  Future<void> updateDepositAvailableAmount() async {
    if (depositCurrency == CryptoCurrency.btcln) {
      final currency = depositCurrency;
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 400));
        if (depositCurrency != currency) {
          return false;
        }
        final balance = wallet.balance[depositCurrency];
        if (balance != null) {
          depositAvailableAmount = _appStore.amountParsingProxy.asDisplayString(balance.available);
          return false;
        }
        return true;
      }).timeout(Duration(seconds: 20));
    } else if (isEVMCompatibleChain(wallet.type)) {
      final currency = depositCurrency;
      final balanceCurrency = wallet.balance.keys.firstWhereOrNull(
        (c) =>
            c.title == depositCurrency.title &&
            (c.tag == depositCurrency.tag || c.tag == depositCurrency.title),
      );
      final balanceForCurrency = balanceCurrency != null ? wallet.balance[balanceCurrency] : null;
      if (depositCurrency == currency && balanceForCurrency != null) {
        depositAvailableAmount =
            _appStore.amountParsingProxy.asDisplayStringWithSymbol(balanceForCurrency.available);
      }
    } else {
      final currency = depositCurrency;
      final sendingBalance = Money.fromInt(
          await unspentCoinsListViewModel.getSendingBalance(UnspentCoinType.any), currency);
      final amount = _appStore.amountParsingProxy.asDisplayStringWithSymbol(sendingBalance);
      if (depositCurrency == currency) {
        depositAvailableAmount = amount;
      }
    }
  }

  void showFiatCurrencyPicker(BuildContext context) {
    FiatCurrencyPickerSheet.show(
      context: context,
      selected: fiat,
      onSelected: (cur) => _settingsStore.fiatCurrency = cur,
    );
  }

  bool useSameWalletAddress(CryptoCurrency currency) =>
      currency == wallet.currency ||
      (currency == CryptoCurrency.btcln &&
          wallet.currency == CryptoCurrency.btc &&
          wallet.isSoftwareWallet) ||
      (currency.tag != null && currency.tag == wallet.currency.tag) ||
      currency.tag == wallet.currency.title;

  bool get isElectrumWallet => [
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.bitcoinCash,
        WalletType.dogecoin
      ].contains(wallet.type);

  bool get hideAddressAfterExchange =>
      [WalletType.monero, WalletType.wownero, WalletType.zcash].contains(wallet.type) ||
      isElectrumWallet;

  bool _useTorOnly;
  final ExchangeTemplateStore _exchangeTemplateStore;
  final TradesStore tradesStore;
  final SharedPreferences sharedPreferences;
  late final pegarouteProviderPreferences = PegarouteProviderPreferences(sharedPreferences);

  List<ExchangeProvider> get _allProviders => [
        ChangeNowExchangeProvider(settingsStore: _settingsStore),
        // SideShiftExchangeProvider(),
        ChainflipExchangeProvider(),
        if (FeatureFlag.isExolixEnabled) ExolixExchangeProvider(),
        SwapTradeExchangeProvider(),
        LetsExchangeExchangeProvider(),
        StealthExExchangeProvider(),
        XOSwapExchangeProvider(),
        SwapsXyzExchangeProvider(),
        JupiterExchangeProvider(),
        NearIntentsExchangeProvider(),
        PegaRouteExchangeProvider(providerPreferences: pegarouteProviderPreferences),
        TrocadorExchangeProvider(
            useTorOnly: _useTorOnly, providerStates: _settingsStore.trocadorProviderStates),
      ];

  @observable
  ExchangeProvider? provider;

  @observable
  ExchangeProvider? providerDisplay;

  /// Maps in dart are not sorted by default
  /// SplayTreeMap is a map sorted by keys
  /// will use it to sort available providers
  /// based on the rate they yield for the current trade
  ///
  ///
  /// initialize with descending comparator
  /// since we want largest rate first
  final SplayTreeMap<double, ExchangeProvider> _sortedAvailableProviders =
      SplayTreeMap<double, ExchangeProvider>((double a, double b) => b.compareTo(a));

  final List<ExchangeProvider> _tradeAvailableProviders = [];

  Map<ExchangeProvider, Limits?> _providerLimits = {};

  @observable
  ObservableList<ExchangeProvider> selectedProviders;

  @observable
  List<ExchangeProvider> providerList;

  @observable
  CryptoCurrency depositCurrency;

  @observable
  CryptoCurrency receiveCurrency;

  @observable
  LimitsState limitsState;

  @observable
  ExchangeTradeState tradeState;

  @observable
  Money? _depositAmount;

  @computed
  bool get hasDepositAmount => _depositAmount != null;

  @computed
  String get depositAmount =>
      _depositAmount == null ? "" : amountParsingProxy.asDisplayString(_depositAmount!);

  @computed
  String get depositAmountCanonical => _depositAmount == null ? "0.0" : _depositAmount.toString();

  @observable
  Money? _receiveAmount;

  @computed
  String get receiveAmount =>
      _receiveAmount == null ? "" : amountParsingProxy.asDisplayString(_receiveAmount!);

  @action
  // only set canonical formated amounts here;
  void setCanonicalReceiveAmount(String value) =>
      _receiveAmount = Money.tryParse(value, receiveCurrency);

  @observable
  String depositAddress;

  @observable
  String receiveAddress;

  @observable
  String receiveAddressExtraId = '';

  @observable
  String? receiveAddressDisplayName;

  @observable
  bool isDepositAddressEnabled;

  @observable
  bool isReceiveAmountEntered;

  @observable
  bool isReceiveAmountEditable;

  @observable
  bool isFixedRateMode;

  @observable
  bool isSendAllEnabled;

  @observable
  Limits limits;

  @observable
  bool tradeStarted = false;

  @observable
  bool noProviderForPair = false;

  @observable
  bool isSendFromExternal = false;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  ObservableList<ExchangeTemplate> get templates => _exchangeTemplateStore.templates;

  @computed
  List<WalletContact> get walletContactsToShow => contactListViewModel.walletContacts
      .where((element) => element.type == receiveCurrency)
      .toList();

  @computed
  List<WalletContact> get refundWalletContactsToShow => contactListViewModel.walletContacts
      .where((element) => element.type == depositCurrency)
      .toList();

  @computed
  Future<List<WalletInfo>> get receiveWallets async {
    try {
      WalletType? type;
      type = cryptoCurrencyOrTokenToWalletType(receiveCurrency);
      if (type == null) {
        type =
            cryptoCurrencyOrTokenToWalletType(CryptoCurrency.fromString(receiveCurrency.tag ?? ""));
      }

      return await WalletInfo.selectList("type = ?", [type!.index]);
    } catch (e) {
      return [];
    }
  }

  Future<List<WalletInfoAddressInfo>> addressesForAccountsWallet(WalletInfo wallet) async {
    final List<WalletInfoAddressInfo> ret = [];
    final addresses = await wallet.getAddressInfos();
    for (var list in addresses.values) {
      // we only want the "primary" account addresses - those that contain account names.
      ret.addAll(list.where((item) => item.label.split(" ").length > 1));
    }
    return ret;
  }

  @computed
  Future<List<WalletInfo>> get depositWallets async {
    WalletType? type;
    type = cryptoCurrencyOrTokenToWalletType(depositCurrency);
    if (type == null) {
      try {
        type =
            cryptoCurrencyOrTokenToWalletType(CryptoCurrency.fromString(depositCurrency.tag ?? ""));
      } catch (_) {}
    }

    if (type != null) {
      return await WalletInfo.selectList("type = ?", [type.index]);
    }

    return await WalletInfo.getAll();
  }

  @action
  bool checkIfWalletIsAnInternalWallet(String address) {
    final walletContactList =
        walletContactsToShow.where((element) => element.address == address).toList();

    return walletContactList.isNotEmpty;
  }

  @computed
  bool get shouldDisplayTOTP2FAForExchangesToInternalWallet =>
      _settingsStore.shouldRequireTOTP2FAForExchangesToInternalWallets;

  @computed
  bool get shouldDisplayTOTP2FAForExchangesToExternalWallet =>
      _settingsStore.shouldRequireTOTP2FAForExchangesToExternalWallets;

  @computed
  String? get balanceDisplay {
    CryptoCurrency? balanceCurrency;
    if (isEVMCompatibleChain(wallet.type) ||
        wallet.type == WalletType.solana ||
        wallet.type == WalletType.tron) {
      balanceCurrency = wallet.balance.keys.firstWhereOrNull(
        (c) =>
            c.title == depositCurrency.title &&
            (c.tag == depositCurrency.tag || c.tag == depositCurrency.title),
      );
    } else {
      balanceCurrency = depositCurrency;
    }
    final bal = balanceCurrency != null ? wallet.balance[balanceCurrency]?.available : null;
    if (bal == null) return null;
    return amountParsingProxy.asDisplayString(bal);
  }

  //* Still open to further optimize these checks
  //* It works but can be made better
  @action
  bool shouldDisplayTOTP() {
    final isInternalWallet = checkIfWalletIsAnInternalWallet(receiveAddress);

    if (isInternalWallet) {
      return shouldDisplayTOTP2FAForExchangesToInternalWallet;
    } else {
      return shouldDisplayTOTP2FAForExchangesToExternalWallet;
    }
  }

  @computed
  bool get decentralizedExchangesPromptDismissed =>
      _settingsStore.decentralizedExchangesPromptDismissed;

  @action
  void dismissDecentralizedExchangesPrompt() {
    _settingsStore.decentralizedExchangesPromptDismissed = true;
  }

  @computed
  TransactionPriority get transactionPriority {
    final priority = _settingsStore.getPriority(wallet.type, chainId: wallet.chainId);

    if (priority == null) {
      throw Exception('Unexpected type ${wallet.type.toString()}');
    }

    return priority;
  }

  bool get hasAllAmount {
    if (_hasPegarouteMax) return true;
    if ([
      WalletType.monero,
      WalletType.bitcoin,
      WalletType.litecoin,
      WalletType.bitcoinCash,
      WalletType.dogecoin,
    ].contains(wallet.type)) return (depositCurrency == wallet.currency);

    if (!isEVMCompatibleChain(wallet.type)) return false;

    if (depositCurrency == wallet.currency) return true;

    return wallet.balance.keys.any((c) =>
        c.title == depositCurrency.title &&
        (c.tag == depositCurrency.tag || c.tag == depositCurrency.title));
  }

  bool get isMoneroWallet => wallet.type == WalletType.monero;

  @observable
  ObservableList<CryptoCurrency> receiveCurrencies;

  @observable
  ObservableList<CryptoCurrency> depositCurrencies;

  final AppStore _appStore;
  SettingsStore get _settingsStore => _appStore.settingsStore;

  final ContactListViewModel contactListViewModel;

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  final FeesViewModel feesViewModel;

  @observable
  double bestRate = 0.0;

  @computed
  bool get useDepositBaseUnit => _appStore.amountParsingProxy.useSatoshi(depositCurrency);

  @computed
  bool get useReceiveBaseUnit => _appStore.amountParsingProxy.useSatoshi(receiveCurrency);

  @computed
  AmountParsingProxy get amountParsingProxy => _appStore.amountParsingProxy;

  @observable
  ExchangeProvider? bestRateProvider;

  @observable
  ExchangeProvider? forcedProvider;

  @action
  void setForcedProvider(ExchangeProvider? provider) {
    forcedProvider = provider;
    forcedProviderRate = 0.0;
    _updateLimits();
    calculateForcedProviderRate();
  }

  WalletInfo? selectedAddressBookWallet;

  @observable
  double forcedProviderRate = 0.0;

  late Timer bestRateSync;

  final FiatConversionStore fiatConversionStore;

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  @computed
  bool get isFiatDisabled => feesViewModel.isFiatDisabled;

  @action
  Future<void> fetchFiatPrice(CryptoCurrency currency) async {
    if (fiatConversionStore.prices[currency] != null) {
      return;
    }

    fiatConversionStore.prices[currency] = await FiatConversionService.fetchPrice(
      crypto: currency,
      fiat: fiat,
      torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly,
    );
  }

  @computed
  String get receiveAmountFiatFormatted {
    var amount = '0.00';
    try {
      if (_receiveAmount != null) {
        if (fiatConversionStore.prices[receiveCurrency] == null) return '';

        amount = calculateFiatAmount(
          price: fiatConversionStore.prices[receiveCurrency]!,
          cryptoAmount: _receiveAmount.toString(),
        );
      }
    } catch (_) {
      log('Error calculating receive amount fiat formatted: $_');
    }
    return isFiatDisabled ? '' : '$amount';
  }

  @computed
  String get depositAmountFiatFormatted {
    var amount = '0.00';
    try {
      if (_depositAmount != null) {
        if (fiatConversionStore.prices[depositCurrency] == null) return '';

        amount = calculateFiatAmount(
          price: fiatConversionStore.prices[depositCurrency]!,
          cryptoAmount: _depositAmount.toString(),
        );
      }
    } catch (_) {
      log('Error calculating deposit amount fiat formatted: $_');
    }
    return isFiatDisabled ? '' : '$amount';
  }

  @computed
  String get receiveAmountFiat {
    var amount = '';
    try {
      if (_receiveAmount != null) {
        if (fiatConversionStore.prices[receiveCurrency] == null) return '';

        amount = calculateFiatAmount(
            price: fiatConversionStore.prices[receiveCurrency]!,
            cryptoAmount: _receiveAmount.toString(),
            raw: true);
      }
    } catch (_) {
      log('Error calculating receive amount fiat formatted: $_');
    }
    return amount;
  }

  @computed
  String get depositAmountFiat {
    var amount = '';
    try {
      if (_depositAmount != null) {
        if (fiatConversionStore.prices[depositCurrency] == null) return '';

        amount = calculateFiatAmount(
          price: fiatConversionStore.prices[depositCurrency]!,
          cryptoAmount: _depositAmount.toString(),
          raw: true,
        );
      }
    } catch (_) {
      log('Error calculating deposit amount fiat formatted: $_');
    }
    return amount;
  }

  String roundedDepositAmount(int digits) {
    if (depositAmount.split(".").last.length <= digits) {
      return depositAmount;
    }
    try {
      return double.parse(depositAmount).toStringAsPrecision(digits);
    } catch (e) {
      return "0";
    }
  }

  String roundedReceiveAmount(int digits) {
    if (receiveAmount.split(".").last.length <= digits) {
      return receiveAmount;
    }
    try {
      return double.parse(receiveAmount).toStringAsPrecision(digits);
    } catch (e) {
      return "0";
    }
  }

  String roundedReceiveAmountFiat(int digits) {
    if (receiveAmountFiat.split(".").last.length <= digits) {
      return receiveAmountFiat;
    }

    return double.tryParse(receiveAmountFiat)?.toStringAsPrecision(digits) ?? '0.00';
  }

  String roundedDepositAmountFiat(int digits) {
    if (depositAmountFiat.split(".").last.length <= digits) {
      return depositAmountFiat;
    }

    return double.tryParse(depositAmountFiat)?.toStringAsPrecision(digits) ?? '0.00';
  }

  @action
  void changeDepositCurrency({required CryptoCurrency currency}) {
    final previousCurrency = depositCurrency;
    final wasSendAllEnabled = isSendAllEnabled;

    depositCurrency = currency;
    isFixedRateMode = false;
    isDepositAddressEnabled = !useSameWalletAddress(depositCurrency);

    if (previousCurrency != currency) {
      _onPairChange(clearBoth: wasSendAllEnabled);
    }
    fetchFiatPrice(currency);
    updateDepositAvailableAmount();
  }

  @action
  void changeReceiveCurrency({required CryptoCurrency currency}) {
    final previousCurrency = receiveCurrency;

    if (!(currency.tag == receiveCurrency.tag ||
        currency.tag == receiveCurrency.title ||
        currency.title == receiveCurrency.tag ||
        currency == receiveCurrency)) {
      receiveAddress = "";
    }
    if (currency != receiveCurrency) {
      receiveAddressExtraId = "";
    }

    receiveCurrency = currency;
    isFixedRateMode = false;
    isDepositAddressEnabled = !useSameWalletAddress(depositCurrency);

    if (previousCurrency != currency) {
      _onPairChange();
    }
    fetchFiatPrice(currency);
  }

  @action
  Future<void> changeReceiveAmount({required String amount, bool isCanonical = false}) async {
    if (amount.isEmpty) {
      _depositAmount = null;
      _receiveAmount = null;
      return;
    }

    _receiveAmount = isCanonical
        ? Money.tryParse(amount.sanitized(), receiveCurrency)
        : _appStore.amountParsingProxy.tryParseCryptoString(amount.sanitized(), receiveCurrency);

    if (_receiveAmount == null) {
      _depositAmount = null;
      return;
    }

    final _enteredAmount = double.tryParse(_receiveAmount.toString()) ?? 0;

    if (bestRate == 0) {
      _depositAmount = null;

      await calculateBestRate();
    }

    final amount_ = _enteredAmount / (forcedProvider == null ? bestRate : forcedProviderRate);
    _depositAmount = amount_.tryToMoney(depositCurrency);
  }

  @action
  void setReceiveAmountFromFiat({required String fiatAmount}) {
    final _enteredAmount = double.tryParse(fiatAmount.sanitized()) ?? 0.0;
    final price = fiatConversionStore.prices[receiveCurrency];
    if (price == null || price == 0.0) return;

    final crypto = _enteredAmount / price;
    final _receiveAmountTmp = crypto.toString().withMaxDecimals(receiveCurrency.decimals);
    if (_receiveAmount != _receiveAmountTmp) {
      changeReceiveAmount(amount: _receiveAmountTmp);
    }
  }

  @action
  void setDepositAmountFromFiat({required String fiatAmount}) {
    final _enteredAmount = double.tryParse(fiatAmount.sanitized()) ?? 0.0;
    final price = fiatConversionStore.prices[depositCurrency];
    if (price == null || price == 0.0) return;

    final crypto = _enteredAmount / price;
    final depositAmountTmp = crypto.toString().withMaxDecimals(depositCurrency.decimals);
    if (_depositAmount != depositAmountTmp) {
      changeDepositAmount(amount: depositAmountTmp, isCanonical: true);
    }
  }

  @action
  Future<void> changeDepositAmount({required String amount, bool isCanonical = false}) async {
    if (amount.isEmpty) {
      _depositAmount = null;
      _receiveAmount = null;
      return;
    }

    _depositAmount = isCanonical
        ? Money.tryParse(amount.sanitized(), depositCurrency)
        : _appStore.amountParsingProxy.tryParseCryptoString(amount.sanitized(), depositCurrency);

    if (_depositAmount == null) {
      _receiveAmount = null;
      return;
    }

    /// For fixed-rate transactions, we don't want to recalculate receive amount
    /// as it should remain exactly what the user set
    if (isFixedRateMode) return;

    final _enteredAmount = double.tryParse(_depositAmount.toString()) ?? 0;

    /// in case the best rate was not calculated yet
    if (bestRate == 0) {
      _receiveAmount = null;

      await calculateBestRate();
    }

    final amount_ = _enteredAmount * (forcedProvider == null ? bestRate : forcedProviderRate);
    _receiveAmount = amount_.tryToMoney(receiveCurrency);
  }

  bool checkIfInputMeetsMinOrMaxCondition(String input) {
    final _enteredAmount = double.tryParse(input.sanitized()) ?? 0;
    double minLimit = limits.min ?? 0;
    double? maxLimit = limits.max;

    if (_enteredAmount < minLimit) return false;

    if (maxLimit != null && _enteredAmount > maxLimit) return false;

    return true;
  }

  // Pegaroute comparisons must not install an older wallet/asset/preference
  // response over a newer selection. Other-provider-only comparisons keep
  // their existing path.
  int _pegarouteComparisonRequest = 0;
  int _pegarouteForcedRequest = 0;
  int? _comparisonPending;
  int? _forcedPending;
  static const _pegarouteQuoteTimeout = Duration(seconds: 20);
  Object _pegarouteRateAsset(CryptoCurrency asset) => (
      identityHashCode(asset), asset.tag, asset.decimals,
      asset is Erc20Token ? (asset.contractAddress, asset.chainId) : null,
      asset is SPLToken ? asset.mint : null);
  Object get _pegarouteRateContext => (
      wallet, wallet.id, wallet.chainId, wallet.walletAddresses.address,
      _pegarouteRateAsset(depositCurrency), _pegarouteRateAsset(receiveCurrency),
      isFixedRateMode ? _receiveAmount?.toString() : depositAmountCanonical,
      isFixedRateMode, isSendAllEnabled, _pegarouteMax, isSendFromExternal, receiveAddressExtraId,
      forcedProvider, forceDecentralizedExchanges,
      selectedProviders.map((p) => p.description.raw).join(','),
      jsonEncode(pegarouteProviderPreferences.states));

  Future<void> calculateForcedProviderRate() async {
    final requestId = ++_pegarouteForcedRequest;
    if (forcedProvider == null || depositCurrency == receiveCurrency) {
      forcedProviderRate = 0.0;
      return;
    }

    final amount =
        double.tryParse(isFixedRateMode ? _receiveAmount.toString() : _depositAmount.toString()) ??
            initialAmountByAssets(isFixedRateMode ? receiveCurrency : depositCurrency);

    if (forcedProvider is PegaRouteExchangeProvider) {
      if (!_canUsePegaroute) {
        forcedProviderRate = 0;
        return;
      }
      final context = _pegarouteRateContext;
      final provider = forcedProvider as PegaRouteExchangeProvider;
      Limits? quoteLimits;
      _forcedPending = requestId;
      final rate = await provider.fetchRateExact(
          from: depositCurrency, to: receiveCurrency, amount: depositAmountCanonical,
          onLimits: (value) => quoteLimits = value)
          .timeout(_pegarouteQuoteTimeout, onTimeout: () => 0.0)
          .whenComplete(() { if (_forcedPending == requestId) _forcedPending = null; });
      if (requestId == _pegarouteForcedRequest && context == _pegarouteRateContext) {
        forcedProviderRate = rate;
        _providerLimits[provider] = quoteLimits;
        _updateLimits();
      }
      return;
    }
    forcedProviderRate = await forcedProvider!.fetchRate(
        from: depositCurrency,
        to: receiveCurrency,
        amount: amount,
        isFixedRateMode: isFixedRateMode,
        isReceiveAmount: isFixedRateMode);
  }

  bool _excludeProviderForSwapAll(ExchangeProvider provider) =>
      isSendAllEnabled &&
      (provider.description == ExchangeProviderDescription.swapsXyz ||
          provider.description == ExchangeProviderDescription.nearIntents);

  bool _excludeProviderForReceiveExtraId(ExchangeProvider provider) =>
      memoLabelTypeFor(receiveCurrency) != null && !provider.supportsMemoOrDestinationTag;

  Future<void> calculateBestRate() async {
    final requestId = ++_pegarouteComparisonRequest;
    final hasPegaroute = selectedProviders.any((p) => p is PegaRouteExchangeProvider) ||
        bestRateProvider is PegaRouteExchangeProvider;
    final context = hasPegaroute ? _pegarouteRateContext : null;
    if (depositCurrency == receiveCurrency) {
      bestRate = 0.0;
      bestRateProvider = null;
      return;
    }
    final amount =
        double.tryParse(isFixedRateMode ? _receiveAmount.toString() : _depositAmount.toString()) ??
            initialAmountByAssets(isFixedRateMode ? receiveCurrency : depositCurrency);

    final validProvidersForAmount = _tradeAvailableProviders.where((provider) {
      if (_excludeProviderForSwapAll(provider)) return false;
      if (_excludeProviderForReceiveExtraId(provider)) return false;
      // A previous minimum must not prevent a fresh Pegaroute quote.
      if (provider is PegaRouteExchangeProvider) return _canUsePegaroute;

      final limits = _providerLimits[provider];

      if (limits == null) return false;
      if (limits.min != null && amount < limits.min!) return false;
      if (limits.max != null && amount > limits.max!) return false;

      return true;
    }).toList();

    final _providers = validProvidersForAmount
        .where((element) => !isFixedRateMode || element.supportsFixedRate)
        .toList();

    final quoteLimits = <ExchangeProvider, Limits?>{};
    _comparisonPending = requestId;
    final result = await Future.wait<double>(
      _providers.map(
        (element) {
          if (element is PegaRouteExchangeProvider) {
            if (!_canUsePegaroute) return Future.value(0.0);
            quoteLimits[element] = null;
            return element
                .fetchRateExact(
                    from: depositCurrency, to: receiveCurrency, amount: depositAmountCanonical,
                    onLimits: (value) => quoteLimits[element] = value)
                .timeout(_pegarouteQuoteTimeout, onTimeout: () => 0.0)
                .onError((error, stackTrace) => 0.0);
          }
          return element
              .fetchRate(
                  from: depositCurrency,
                  to: receiveCurrency,
                  amount: amount,
                  isFixedRateMode: isFixedRateMode,
                  isReceiveAmount: isFixedRateMode)
              .timeout(
                Duration(seconds: 7),
                onTimeout: () => 0.0,
              )
              // One unavailable provider must not stop the remaining quotes.
              .onError((error, stackTrace) => 0.0);
        },
      ),
    ).whenComplete(() { if (_comparisonPending == requestId) _comparisonPending = null; });

    if (hasPegaroute &&
        (requestId != _pegarouteComparisonRequest || context != _pegarouteRateContext)) return;

    // We'll use a new SplayTreeMap to avoid concurrent modification issues
    final newSortedProviders =
        SplayTreeMap<double, ExchangeProvider>((double a, double b) => b.compareTo(a));

    for (int i = 0; i < result.length; i++) {
      if (result[i] != 0) {
        /// add this provider as its valid for this trade
        try {
          newSortedProviders[result[i]] = _providers[i];
        } catch (e) {
          // will throw "Concurrent modification during iteration" error if modified at the same
          // time [createTrade] is called, as this is not a normal map, but a sorted map
        }
      } else {
        printV('calculateBestRate: ${_providers[i].title} returned rate=0');
      }
    }

    // Replace the old map with the new one
    _sortedAvailableProviders.clear();
    _sortedAvailableProviders.addAll(newSortedProviders);
    // Empty results must clear the previous quote, including other providers.
    bestRate = 0;
    bestRateProvider = null;

    if (_sortedAvailableProviders.isNotEmpty) {
      bestRate = _sortedAvailableProviders.keys.first;
      bestRateProvider = _sortedAvailableProviders.values.first;
    }
    noProviderForPair = _sortedAvailableProviders.isEmpty;
    // The forced quote owns its limits, independently of the automatic comparison.
    _providerLimits.addEntries(quoteLimits.entries.where((entry) => entry.key != forcedProvider));
    _updateLimits(fromQuotes: true);
  }

  int _limitsRequest = 0;
  Object get _limitsContext => (
      _pegarouteRateAsset(depositCurrency), _pegarouteRateAsset(receiveCurrency), isFixedRateMode,
      selectedProviders.map(identityHashCode).join(','),
      jsonEncode(pegarouteProviderPreferences.states));

  @action
  Future<void> loadLimits() async {
    final requestId = ++_limitsRequest;
    final context = _limitsContext;
    _providerLimits.clear();
    limits = Limits(min: 0, max: null);
    if (depositCurrency == receiveCurrency || selectedProviders.isEmpty) {
      _updateLimits();
      return;
    }
    limitsState = LimitsIsLoading();

    final from = isFixedRateMode ? receiveCurrency : depositCurrency;
    final to = isFixedRateMode ? depositCurrency : receiveCurrency;
    final providers = selectedProviders
        .where((provider) => providerList.contains(provider))
        .where((provider) => !_excludeProviderForReceiveExtraId(provider)).toList();
    final entries = await Future.wait(providers.map((provider) async {
      final limits = await provider.fetchLimits(from: from, to: to, isFixedRateMode: isFixedRateMode)
          .onError((error, stackTrace) => null)
          .timeout(Duration(seconds: 7), onTimeout: () => null);
      return MapEntry(provider, limits);
    }));
    if (requestId != _limitsRequest || context != _limitsContext) return;
    for (final entry in entries) {
      // A current quote may finish while other providers still load their limits.
      if (entry.key is PegaRouteExchangeProvider && _providerLimits.containsKey(entry.key)) continue;
      _providerLimits[entry.key] = entry.value;
    }
    _updateLimits();
    calculateBestRate();
  }

  void _updateLimits({bool fromQuotes = false}) {
    double? lowestMin = double.maxFinite;
    double? highestMax = 0.0;
    final amount = double.tryParse(isFixedRateMode ? _receiveAmount.toString() : depositAmountCanonical);
    final ranges = selectedProviders
        .where((provider) => providerList.contains(provider))
        .where((provider) => forcedProvider == null || provider == forcedProvider)
        .where((provider) => !_excludeProviderForSwapAll(provider) &&
            !_excludeProviderForReceiveExtraId(provider))
        .where((provider) => provider is! PegaRouteExchangeProvider || _canUsePegaroute)
        .where((provider) {
          if (!fromQuotes || forcedProvider != null || amount == null ||
              _sortedAvailableProviders.containsValue(provider)) return true;
          final range = _providerLimits[provider];
          // Keep amount limits, but not a zero minimum from a failed quote.
          return (range?.min != null && amount < range!.min!) ||
              (range?.max != null && amount > range!.max!);
        })
        .map((provider) => _providerLimits[provider]).whereType<Limits>();
    for (final range in ranges) {
      if (lowestMin != null && (range.min ?? -1) < lowestMin) lowestMin = range.min;
      if (highestMax != null && (range.max ?? double.maxFinite) > highestMax) highestMax = range.max;
    }
    limits = lowestMin == double.maxFinite
        ? Limits(min: 0, max: null)
        : Limits(min: lowestMin, max: highestMax);
    limitsState = lowestMin == double.maxFinite
        ? LimitsLoadedFailure(error: 'Limits loading failed')
        : LimitsLoadedSuccessfully(limits: limits);
  }

  bool get _hasPegarouteMax =>
      selectedProviders.any((p) => p is PegaRouteExchangeProvider) &&
      PegaRouteExchangeProvider.supportsMax(wallet, depositCurrency);

  int _pegarouteMaxRequest = 0;
  ({Object context, BigInt balance, String amount})? _pegarouteMax;
  Object get _pegarouteMaxContext => (wallet, wallet.id, wallet.chainId,
      wallet.walletAddresses.address, _pegarouteRateAsset(depositCurrency),
      isSendAllEnabled, isFixedRateMode);
  bool get _pegarouteMaxIsCurrent => _hasPegarouteMax &&
      _pegarouteMax?.context == _pegarouteMaxContext &&
      _pegarouteMax?.amount == depositAmountCanonical &&
      _pegarouteMax?.balance == PegaRouteExchangeProvider.sourceBalance(wallet, depositCurrency)?.amount;

  bool get _canUsePegaroute =>
      !isFixedRateMode && (!isSendAllEnabled || _pegarouteMaxIsCurrent) &&
      (PegaRouteExchangeProvider.allowsExternal(ExchangeProviderDescription.pegaRoute) ||
          !isSendFromExternal) &&
      PegaRouteExchangeProvider.supportsWallet(wallet, depositCurrency) &&
      receiveAddressExtraId.trim().isEmpty &&
      PegaRouteExchangeProvider.supportsPair(depositCurrency, receiveCurrency);

  // One Pegaroute-only snapshot; the predicate is reused across every await and installation.
  ({Future<Trade> Function(PegaRouteExchangeProvider) create,
    bool Function(PegaRouteExchangeProvider) current}) _capturePegarouteCreation() {
    final boundWallet = wallet;
    final preferences = Map<String, bool>.from(pegarouteProviderPreferences.states);
    final decentralizedOnly = forceDecentralizedExchanges;
    final walletId = wallet.id;
    final sender = wallet.walletAddresses.address;
    final chainId = wallet.chainId;
    final sendAll = isSendAllEnabled;
    final maxBalance = _pegarouteMax?.balance;
    final request = TradeRequest(fromCurrency: depositCurrency, toCurrency: receiveCurrency,
        fromAmount: depositAmountCanonical, toAddress: receiveAddress, refundAddress: depositAddress);
    final principal = Money.parse(request.fromAmount, request.fromCurrency);
    bool hasPrincipal() {
      final balance = PegaRouteExchangeProvider.sourceBalance(boundWallet, request.fromCurrency);
      return balance != null && balance.amount >= principal.amount &&
          (!sendAll || balance.amount == maxBalance);
    }
    bool current(PegaRouteExchangeProvider provider) =>
        _canUsePegaroute && sendAll == isSendAllEnabled && selectedProviders.contains(provider) &&
        decentralizedOnly == forceDecentralizedExchanges &&
        const MapEquality<String, bool>().equals(preferences, pegarouteProviderPreferences.states) &&
        identical(wallet, boundWallet) && wallet.id == walletId &&
        wallet.walletAddresses.address == sender && wallet.chainId == chainId &&
        PegaRouteExchangeProvider.sameAsset(depositCurrency, request.fromCurrency) &&
        PegaRouteExchangeProvider.sameAsset(receiveCurrency, request.toCurrency) &&
        depositAmountCanonical == request.fromAmount && receiveAddress == request.toAddress &&
        depositAddress == request.refundAddress && hasPrincipal();
    return (current: current, create: (provider) async {
      if (!hasPrincipal()) throw StateError('Source balance changed or is insufficient. Request a new quote.');
      if (!current(provider)) throw StateError('Wallet or quote intent changed');
      return provider.createBoundTrade(request: request, walletId: walletId, sender: sender,
          chainId: chainId, isFixedRateMode: false, isSendAll: false,
          isCurrent: () => current(provider));
    });
  }

  @action
  Future<void> createTrade() async {
    final pegarouteIntent = selectedProviders.any((p) => p is PegaRouteExchangeProvider)
        ? _capturePegarouteCreation()
        : null;
    final depositAmountValue = _depositAmount ?? Money.zero(depositCurrency);
    final receiveAmountValue = _receiveAmount ?? Money.zero(receiveCurrency);

    if (depositAmountValue.isZero ||
        depositAmountValue.isNegative ||
        receiveAmountValue.isZero ||
        receiveAmountValue.isNegative) {
      ExchangeProviderLogger.logError(
        provider: forcedProvider?.description ?? bestRateProvider?.description,
        function: 'createTrade',
        error: 'Invalid swap amount: deposit=$_depositAmount receive=$_receiveAmount',
        requestData: {
          'from': depositCurrency.title,
          'to': receiveCurrency.title,
          'fromAmount': _depositAmount,
          'toAmount': _receiveAmount,
          'isFixedRateMode': isFixedRateMode,
          'forcedProvider': forcedProvider?.title,
          'bestRateProvider': bestRateProvider?.title,
        },
      );

      final invalidAmountError = depositAmountValue.isZero || depositAmountValue.isNegative
          ? '$depositAmountValue is not a valid amount for depositAmount'
          : '$receiveAmountValue is not a valid amount for receiveAmount';

      tradeState =
          TradeIsCreatedFailure(title: S.current.trade_not_created, error: invalidAmountError);
      return;
    }

    if (isSendAllEnabled) {
      await calculateDepositAllAmount();
      final amount = double.tryParse(_depositAmount.toString());

      if (limits.min != null && amount != null && amount < limits.min!) {
        tradeState = TradeIsCreatedFailure(
          title: S.current.trade_not_created,
          error: S.current.amount_is_below_minimum_limit(limits.min!.toString()),
        );
        return;
      }
    }

    if (depositCurrency == CryptoCurrency.btcln &&
        wallet.type == WalletType.bitcoin &&
        depositAddress == wallet.walletAddresses.addressForExchange) {
      final invoice = await bitcoin!.getLightningInvoice(wallet, BigInt.zero);
      if (invoice != null) {
        depositAddress = invoice;
      }
    }

    if (receiveCurrency == CryptoCurrency.btcln &&
        wallet.type == WalletType.bitcoin &&
        receiveAddress == wallet.walletAddresses.addressForExchange) {
      final invoice = await bitcoin!.getLightningInvoice(wallet, BigInt.zero);
      if (invoice != null) {
        receiveAddress = invoice;
      }
    }

    if (forcedProvider != null && _excludeProviderForReceiveExtraId(forcedProvider!)) {
      tradeState = TradeIsCreatedFailure(
        title: S.current.trade_not_created,
        error: S.current.none_of_selected_providers_can_exchange,
      );
      return;
    }

    Map<double, ExchangeProvider> providers;
    if (forcedProvider != null) {
      providers = {forcedProviderRate: forcedProvider!};
    } else {
      providers = Map.fromEntries(
        _sortedAvailableProviders.entries.where(
          (e) => selectedProviders.contains(e.value),
        ),
      );
    }

    // Ensure we have providers available before attempting to create trade
    if (providers.isEmpty) {
      await calculateBestRate();
      if (forcedProvider != null) {
        providers = {forcedProviderRate: forcedProvider!};
      } else {
        providers = Map.fromEntries(
          _sortedAvailableProviders.entries.where(
            (e) => selectedProviders.contains(e.value),
          ),
        );
      }

      if (providers.isEmpty) {
        ExchangeProviderLogger.logError(
          provider: null,
          function: 'createTrade',
          error: 'No providers available for $depositCurrency->$receiveCurrency',
          requestData: {
            'from': depositCurrency.title,
            'to': receiveCurrency.title,
            'fromAmount': _depositAmount,
            'toAmount': _receiveAmount,
          },
        );
        tradeState = TradeIsCreatedFailure(
            title: S.current.trade_not_created,
            error: S.current.none_of_selected_providers_can_exchange);
        return;
      }
    }

    try {
      if (selectedAddressBookWallet?.type == WalletType.bitcoin) {
        final _walletAddresses = await selectedAddressBookWallet!.getAddresses();

        // if receive currency is lightning pick the lightning address
        // if normal bitcoin, then pick the segwit address
        if (receiveCurrency == CryptoCurrency.btcln) {
          final lightningAddressOfWallet =
              _walletAddresses.entries.firstWhereOrNull((e) => e.value.contains("LN"))?.key;
          if (lightningAddressOfWallet != null) {
            receiveAddress = lightningAddressOfWallet;
          }
        }
        if (receiveCurrency == CryptoCurrency.btc) {
          final segwitAddressOfWallet =
              _walletAddresses.entries.firstWhereOrNull((e) => e.value.contains("P2WPKH"))?.key;
          if (segwitAddressOfWallet != null) {
            receiveAddress = segwitAddressOfWallet;
          }
        }
      }

      if (receiveCurrency == CryptoCurrency.zec &&
          selectedAddressBookWallet?.type == WalletType.zcash) {
        if (wallet.type == WalletType.zcash && wallet.name == selectedAddressBookWallet!.name) {
          receiveAddress = wallet.walletAddresses.addressForExchange;
        } else {
          receiveAddress = (await selectedAddressBookWallet!.getAddresses())
                  .entries
                  .firstWhereOrNull((e) => e.value == 'transparent')
                  ?.key ??
              receiveAddress;
        }
      }

      // parse Lightning address to bolt11 invoice
      if (receiveAddress.contains("@")) {
        receiveAddress = await getBolt11FromLightingAddress(receiveAddress) ?? receiveAddress;
      }

      // snapshot of providers to avoid concurrent modification issues
      final providersSnapshot = providers.values.toList();
      final ratesSnapshot = providers.keys.toList();

      for (var i = 0; i < providersSnapshot.length; i++) {
        final provider = providersSnapshot[i];
        final providerRate = ratesSnapshot[i];

        printV('createTrade: trying provider=${provider.title}');

        if (_excludeProviderForSwapAll(provider)) {
          printV('Skipping Swaps.xyz or Near Intents for swap all');
          continue;
        }
        // should not happen but just as an extra check
        if (isFixedRateMode && provider.supportsFixedRate == false) {
          continue;
        }

        if (_excludeProviderForReceiveExtraId(provider)) {
          continue;
        }

        if (provider is PegaRouteExchangeProvider && !_canUsePegaroute) {
          continue;
        }

        // Skip Swaps.xyz when sending from external
        if (isSendFromExternal && provider.description == ExchangeProviderDescription.swapsXyz) {
          printV('Skipping Swaps.xyz for external send');
          continue;
        }

        if (!(await provider.checkIsAvailable())) continue;

        bestRate = providerRate;
        bestRateProvider = provider;

        await changeDepositAmount(amount: _depositAmount.toString(), isCanonical: true);

        final request = TradeRequest(
          fromCurrency: depositCurrency,
          toCurrency: receiveCurrency,
          fromAmount: _depositAmount.toString(),
          toAmount: _receiveAmount.toString(),
          refundAddress: depositAddress,
          toAddress: receiveAddress,
          toAddressExtraId: receiveAddressExtraId.trim(),
          isFixedRate: isFixedRateMode,
        );

        if (hideAddressAfterExchange) {
          wallet.walletAddresses.hiddenAddresses.add(depositAddress);
          await wallet.walletAddresses.saveAddressesInBox();
        }

        var amount = isFixedRateMode ? _receiveAmount.toString() : _depositAmount.toString();

        if (provider is PegaRouteExchangeProvider) {
          // Creation rechecks the exact quote. UI limits are not funding authority.
          try {
            tradeState = TradeIsCreating();
            if (pegarouteIntent == null) throw StateError('Missing Pegaroute creation intent');
            final trade = await pegarouteIntent.create(provider);
            if (!pegarouteIntent.current(provider)) {
              throw StateError('Order saved for previous wallet intent; do not repay');
            }
            tradesStore.setTrade(trade); // Already persisted by the provider.
            tradeState = TradeIsCreatedSuccessfully(trade: trade);
          } catch (error) {
            // Creation/persistence may have succeeded: never fall back or log intent.
            tradeState = TradeIsCreatedFailure(title: S.current.trade_not_created, error: error.toString());
          }
          return;
        }

        if (limitsState is LimitsLoadedSuccessfully) {
          if (double.tryParse(amount) == null) {
            printV('createTrade: ${provider.title} amount parse failed: "$amount"');
            continue;
          }

          if (limits.min != null && double.parse(amount) < limits.min!) {
            continue;
          } else if (limits.max != null && double.parse(amount) > limits.max!) {
            continue;
          } else {
            try {
              tradeState = TradeIsCreating();
              final trade = await provider.createTrade(
                request: request,
                isFixedRateMode: isFixedRateMode,
                isSendAll: isSendAllEnabled,
              );
              trade.walletId = wallet.id;
              trade.chainId = wallet.chainId;
              trade.fromWalletAddress = wallet.walletAddresses.address;
              if (trade.from == null) {
                trade.from = depositCurrency;
              }
              if (trade.to == null) {
                trade.to = receiveCurrency;
              }

              final canCreateTrade = await isCanCreateTrade(trade);
              if (!canCreateTrade.result) {
                ExchangeProviderLogger.logError(
                  provider: provider.description,
                  function: 'createTrade',
                  error: canCreateTrade.errorMessage ?? 'isCanCreateTrade returned false',
                  requestData: {
                    'from': depositCurrency.title,
                    'to': receiveCurrency.title,
                    'fromAmount': _depositAmount,
                    'toAmount': _receiveAmount,
                  },
                );
                continue;
              }

              tradesStore.setTrade(trade);
              if (trade.provider != ExchangeProviderDescription.thorChain) await trade.save();
              tradeState = TradeIsCreatedSuccessfully(trade: trade);

              /// return after the first successful trade
              return;
            } catch (e, s) {
              ExchangeProviderLogger.logError(
                provider: provider.description,
                function: 'createTrade',
                error: e,
                stackTrace: s,
                requestData: {
                  'from': depositCurrency.title,
                  'to': receiveCurrency.title,
                  'fromAmount': _depositAmount,
                  'toAmount': _receiveAmount,
                  'toAddress': receiveAddress,
                  'refundAddress': depositAddress,
                },
              );
              continue;
            }
          }
        }
      }

      /// if the code reached here then none of the providers succeeded
      tradeState = TradeIsCreatedFailure(
          title: S.current.trade_not_created,
          error: S.current.none_of_selected_providers_can_exchange);
    } on ConcurrentModificationError {
      /// if create trade happened at the exact same time of the scheduled rate update
      /// then delay the create trade a bit and try again
      ///
      /// this is because the limitation of the SplayTreeMap that
      /// you can't modify it while iterating through it
      Future.delayed(Duration(milliseconds: 200), createTrade);
    }
  }

  @action
  void reset() {
    _initialPairBasedOnWallet();
    isReceiveAmountEntered = false;
    _depositAmount = null;
    _receiveAmount = null;
    depositAddress =
        depositCurrency == wallet.currency ? wallet.walletAddresses.addressForExchange : '';
    receiveAddress =
        receiveCurrency == wallet.currency ? wallet.walletAddresses.addressForExchange : '';
    receiveAddressExtraId = '';
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isFixedRateMode = false;
    _onPairChange();
  }

  @action
  void enableSendAllAmount() {
    isSendAllEnabled = true;
    isFixedRateMode = false;
    calculateDepositAllAmount();
  }

  @action
  void enableFixedRateMode() {
    isSendAllEnabled = false;
    isFixedRateMode = true;
  }

  @action
  Future<void> calculateDepositAllAmount() async {
    if (_hasPegarouteMax) {
      final request = ++_pegarouteMaxRequest;
      final context = _pegarouteMaxContext;
      final boundWallet = wallet;
      final currency = depositCurrency;
      final balance = PegaRouteExchangeProvider.sourceBalance(boundWallet, currency)!;
      _pegarouteMax = null;
      bool current() => request == _pegarouteMaxRequest && context == _pegarouteMaxContext &&
          _hasPegarouteMax &&
          PegaRouteExchangeProvider.sourceBalance(boundWallet, currency)?.amount == balance.amount;
      String amount = '0';
      try {
        final priority = _settingsStore.getPriority(boundWallet.type, chainId: boundWallet.chainId);
        final maximum = await pegarouteMaxAmount(boundWallet, balance, priority);
        if (!current()) return;
        amount = maximum.toString();
        _pegarouteMax = (context: context, balance: balance.amount, amount: amount);
      } catch (_) {
        if (!current()) return;
        // Do not use the full native balance when a fee estimate fails.
      }
      await changeDepositAmount(amount: amount, isCanonical: true);
      if (!current()) return;
      await calculateBestRate();
      if (current() && forcedProvider is PegaRouteExchangeProvider) {
        await calculateForcedProviderRate();
      }
      return;
    }
    if ([
      WalletType.litecoin,
      WalletType.bitcoin,
      WalletType.bitcoinCash,
      WalletType.dogecoin,
    ].contains(wallet.type)) {
      final priority = _settingsStore.getPriority(wallet.type)!;

      final amount = depositCurrency == CryptoCurrency.btcln
          // FIXME amount estimation is broken/impossible for ln, konsti suggested this
          ? (amountParsingProxy.parseCryptoString(depositAvailableAmount, depositCurrency) -
              Money.fromInt(10, depositCurrency))
          : await bitcoin!.estimateFakeSendAllTxAmount(
              wallet,
              priority,
              coinTypeToSpendFrom: wallet.type == WalletType.litecoin
                  ? UnspentCoinType.nonMweb
                  : depositCurrency == CryptoCurrency.btcln
                      ? UnspentCoinType.lightning
                      : UnspentCoinType.any,
            );

      changeDepositAmount(amount: amount.toString(), isCanonical: true);
    } else if (wallet.type == WalletType.monero) {
      final amount = await unspentCoinsListViewModel.getSendingBalance(UnspentCoinType.any);

      changeDepositAmount(
          amount: wallet.currency.formatAmount(BigInt.from(amount)), isCanonical: true);
    } else if (isEVMCompatibleChain(wallet.type)) {
      final balanceCurrency = wallet.balance.keys.firstWhereOrNull(
        (currency) =>
            currency.title == depositCurrency.title &&
            (currency.tag == depositCurrency.tag || currency.tag == depositCurrency.title),
      );

      final balanceForCurrency = balanceCurrency != null ? wallet.balance[balanceCurrency] : null;
      if (balanceForCurrency == null) {
        changeDepositAmount(amount: wallet.currency.formatAmount(BigInt.zero), isCanonical: true);
        return;
      }

      final balanceAmount =
          _appStore.amountParsingProxy.asDisplayString(balanceForCurrency.available);
      final balanceDouble = double.tryParse(balanceAmount.replaceAll(',', '.')) ?? 0.0;
      if (balanceDouble <= 0) {
        changeDepositAmount(amount: wallet.currency.formatAmount(BigInt.zero), isCanonical: true);
        return;
      }

      final isNative = depositCurrency == wallet.currency;

      if (!isNative) {
        changeDepositAmount(amount: balanceAmount, isCanonical: true);
        return;
      }

      try {
        final priority = _settingsStore.getPriority(wallet.type, chainId: wallet.chainId);
        await wallet.updateEstimatedFeesParams(priority);

        String? feeString;
        if (isEVMCompatibleChain(wallet.type)) {
          feeString = evm!.getEVMNativeEstimatedFee(wallet);
        }

        if (feeString == null || feeString.isEmpty) {
          changeDepositAmount(amount: balanceAmount, isCanonical: true);
          return;
        }

        final balanceWei = balanceForCurrency.available.amount;
        final feeWei = BigInt.parse(feeString);
        final amountAfterFeeWei = balanceWei > feeWei ? balanceWei - feeWei : BigInt.zero;
        changeDepositAmount(
            amount: wallet.currency.formatAmount(amountAfterFeeWei), isCanonical: true);
      } catch (e) {
        printV('Error calculating send all for EVM: $e');
        changeDepositAmount(amount: balanceAmount, isCanonical: true);
      }
    }
  }

  @observable
  String depositAvailableAmount = "";

  @action
  void reverseSwapDirection() {
    final tmpAmount = _receiveAmount;
    final tmpCurrency = depositCurrency;
    changeDepositCurrency(currency: receiveCurrency);
    changeReceiveCurrency(currency: tmpCurrency);
    _depositAmount = tmpAmount;
  }

  void updateTemplate() => _exchangeTemplateStore.update();

  void addTemplate(
          {required String amount,
          required String depositCurrency,
          required String receiveCurrency,
          required String provider,
          required String depositAddress,
          required String receiveAddress,
          required String depositCurrencyTitle,
          required String receiveCurrencyTitle}) =>
      _exchangeTemplateStore.addTemplate(
          amount: amount,
          depositCurrency: depositCurrency,
          receiveCurrency: receiveCurrency,
          provider: provider,
          depositAddress: depositAddress,
          receiveAddress: receiveAddress,
          depositCurrencyTitle: depositCurrencyTitle,
          receiveCurrencyTitle: receiveCurrencyTitle);

  void removeTemplate({required ExchangeTemplate template}) =>
      _exchangeTemplateStore.remove(template: template);

  void _onPairChange({bool clearBoth = false}) {
    if (clearBoth) {
      _depositAmount = null;
      _receiveAmount = null;
      if (!hasAllAmount) isSendAllEnabled = false;
    } else {
      if (isFixedRateMode) {
        _depositAmount = null;
      } else {
        _receiveAmount = null;
      }
    }
    bestRate = 0.0;
    bestRateProvider = null;
    _sortedAvailableProviders.clear();
    loadLimits().then((_) {
      if (clearBoth && hasAllAmount) {
        calculateDepositAllAmount();
      }
    });
    _setAvailableProviders();
  }

  void _initialPairBasedOnWallet() {
    if (isEVMCompatibleChain(wallet.type)) {
      depositCurrency = wallet.currency;
      receiveCurrency = CryptoCurrency.xmr;
      return;
    }

    switch (wallet.type) {
      case WalletType.monero:
        depositCurrency = CryptoCurrency.xmr;
        receiveCurrency = CryptoCurrency.btc;
        break;
      case WalletType.bitcoin:
        depositCurrency = CryptoCurrency.btc;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.litecoin:
        depositCurrency = CryptoCurrency.ltc;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.bitcoinCash:
        depositCurrency = CryptoCurrency.bch;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.dogecoin:
        depositCurrency = CryptoCurrency.doge;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.haven:
        depositCurrency = CryptoCurrency.xhv;
        receiveCurrency = CryptoCurrency.btc;
        break;
      case WalletType.ethereum:
        depositCurrency = CryptoCurrency.eth;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.nano:
        depositCurrency = CryptoCurrency.nano;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.banano:
        depositCurrency = CryptoCurrency.banano;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.polygon:
        depositCurrency = CryptoCurrency.maticpoly;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.base:
        depositCurrency = CryptoCurrency.baseEth;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.arbitrum:
        depositCurrency = CryptoCurrency.arbEth;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.bsc:
        depositCurrency = CryptoCurrency.bnb;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.solana:
        depositCurrency = CryptoCurrency.sol;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.tron:
        depositCurrency = CryptoCurrency.trx;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.wownero:
        depositCurrency = CryptoCurrency.wow;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.zano:
        depositCurrency = CryptoCurrency.zano;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.decred:
        depositCurrency = CryptoCurrency.dcr;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.zcash:
        depositCurrency = CryptoCurrency.zec;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.none:
        break;
    }
  }

  void _defineIsReceiveAmountEditable() {
    /*if ((provider is ChangeNowExchangeProvider)
        &&(depositCurrency == CryptoCurrency.xmr)
        &&(receiveCurrency == CryptoCurrency.btc)) {
      isReceiveAmountEditable = true;
    } else {
      isReceiveAmountEditable = false;
    }*/
    //isReceiveAmountEditable = false;
    // isReceiveAmountEditable = selectedProviders.any((provider) => provider is ChangeNowExchangeProvider);
    // isReceiveAmountEditable = provider is ChangeNowExchangeProvider ||  provider is SimpleSwapExchangeProvider;
    isReceiveAmountEditable = true;
  }

  @action
  void addExchangeProvider(ExchangeProvider provider) {
    if (provider.description.isCentralized && forceDecentralizedExchanges) return;
    if (!selectedProviders.contains(provider)) selectedProviders.add(provider);
    if (providerList.contains(provider)) _tradeAvailableProviders.add(provider);
  }

  @action
  void removeExchangeProvider(ExchangeProvider provider) {
    selectedProviders.remove(provider);
    _tradeAvailableProviders.remove(provider);
    if (forcedProvider == provider) {
      setForcedProvider(null);
    }
  }

  @action
  void saveSelectedProviders() {
    _depositAmount = null;
    _receiveAmount = null;
    isFixedRateMode = false;
    _defineIsReceiveAmountEditable();
    bestRateProvider = null;
    bestRate = 0.0;
    loadLimits();

    final Map<String, dynamic> exchangeProvidersSelection =
        json.decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}")
            as Map<String, dynamic>;

    for (var provider in providerList) {
      exchangeProvidersSelection[provider.title] = selectedProviders.contains(provider);
    }

    sharedPreferences.setString(
      PreferencesKey.exchangeProvidersSelection,
      json.encode(exchangeProvidersSelection),
    );
  }

  @action
  Future<void> updateAllTrocadorProviderStates(TrocadorExchangeProvider trocadorProvider) async {
    try {
      var providers = await trocadorProvider.fetchProviders();
      var providerNames = providers.map((e) => e.name).toList();
      await _settingsStore.updateAllTrocadorProviderStates(providerNames);
    } catch (e) {
      printV('Error updating trocador provider states: $e');
    }
  }

  bool get isAvailableInSelected {
    return selectedProviders
        .any((element) => element.isAvailable && providerList.contains(element));
  }

  @computed
  bool get forceDecentralizedExchanges => _settingsStore.forceDecentralizedExchanges;

  @action
  void toggleForceDecentralizedExchanges() {
    _settingsStore.forceDecentralizedExchanges = !_settingsStore.forceDecentralizedExchanges;
    if (forceDecentralizedExchanges) {
      final providers = selectedProviders.toList();
      for (final provider in providers) {
        if (forceDecentralizedExchanges && provider.description.isCentralized) {
          removeExchangeProvider(provider);
        }
      }
    } else {
      for (final provider in providerList) {
        if (!selectedProviders.contains(provider) && provider.description.isCentralized) {
          addExchangeProvider(provider);
        }
      }
    }
  }

  void _setAvailableProviders() {
    _tradeAvailableProviders.clear();

    _tradeAvailableProviders
        .addAll(selectedProviders.where((provider) => providerList.contains(provider)));
  }

  void _setProviders() {
    if (_settingsStore.exchangeStatus == ExchangeApiMode.torOnly)
      providerList = _allProviders.where((provider) => provider.supportsOnionAddress).toList();
    else
      providerList = _allProviders;
  }

  int get depositMaxDigits => depositCurrency.decimals;

  int get receiveMaxDigits => receiveCurrency.decimals;

  Future<CreateTradeResult> isCanCreateTrade(Trade trade) async {
    if (trade.provider == ExchangeProviderDescription.swapsXyz) {
      final tradeFrom = trade.from;

      if (tradeFrom == null) {
        return CreateTradeResult(
          result: false,
          errorMessage: 'From currency is null',
        );
      }

      final isNativeSupportedToken =
          walletTypes.contains(cryptoCurrencyOrTokenToWalletType(tradeFrom));

      if (!isNativeSupportedToken) {
        bool _isEthToken() =>
            wallet.currency == CryptoCurrency.eth && tradeFrom.tag == CryptoCurrency.eth.title;

        bool _isPolygonToken() =>
            wallet.currency == CryptoCurrency.maticpoly &&
            tradeFrom.tag == CryptoCurrency.maticpoly.tag;

        bool _isBaseToken() =>
            wallet.currency == CryptoCurrency.baseEth &&
            tradeFrom.tag == CryptoCurrency.baseEth.tag;

        bool _isTronToken() =>
            wallet.currency == CryptoCurrency.trx && tradeFrom.tag == CryptoCurrency.trx.title;

        bool _isSplToken() =>
            wallet.currency == CryptoCurrency.sol && tradeFrom.tag == CryptoCurrency.sol.title;

        bool isArbitrumToken() =>
            wallet.currency == CryptoCurrency.arbEth && tradeFrom.tag == CryptoCurrency.arbEth.tag;

        bool isBscToken() =>
            wallet.currency == CryptoCurrency.bnb && tradeFrom.tag == CryptoCurrency.bnb.tag;

        if (!(_isEthToken() ||
            _isPolygonToken() ||
            _isBaseToken() ||
            _isTronToken() ||
            _isSplToken() ||
            isArbitrumToken() ||
            isBscToken())) {
          return CreateTradeResult(
            result: false,
            errorMessage:
                'This token isn’t supported on the current wallet/network for Swaps.xyz. Switch to a supported wallet or asset',
          );
        }
      }
    }

    if (trade.provider == ExchangeProviderDescription.thorChain) {
      final payoutAddress = trade.payoutAddress ?? '';
      final fromWalletAddress = trade.fromWalletAddress ?? '';
      final tapRootPattern = RegExp(P2trAddress.regex.pattern);

      if (tapRootPattern.hasMatch(payoutAddress) || tapRootPattern.hasMatch(fromWalletAddress)) {
        return CreateTradeResult(
          result: false,
          errorMessage: S.current.thorchain_taproot_address_not_supported,
        );
      }

      if ((trade.memo == null || trade.memo!.isEmpty)) {
        return CreateTradeResult(
          result: false,
          errorMessage: 'Memo is required for Thorchain trade',
        );
      }

      final currenciesToCheckPattern = RegExp('0x[0-9a-zA-Z]');

      // Perform checks for payOutAddress
      final isPayOutAddressAccordingToPattern = currenciesToCheckPattern.hasMatch(payoutAddress);

      if (isPayOutAddressAccordingToPattern) {
        final isPayOutAddressEOA = await _isExternallyOwnedAccountAddress(payoutAddress);

        return CreateTradeResult(
          result: isPayOutAddressEOA,
          errorMessage:
              !isPayOutAddressEOA ? S.current.thorchain_contract_address_not_supported : null,
        );
      }

      // Perform checks for fromWalletAddress
      final isFromWalletAddressAddressAccordingToPattern =
          currenciesToCheckPattern.hasMatch(fromWalletAddress);

      if (isFromWalletAddressAddressAccordingToPattern) {
        final isFromWalletAddressEOA = await _isExternallyOwnedAccountAddress(fromWalletAddress);

        return CreateTradeResult(
          result: isFromWalletAddressEOA,
          errorMessage:
              !isFromWalletAddressEOA ? S.current.thorchain_contract_address_not_supported : null,
        );
      }
    }
    return CreateTradeResult(result: true);
  }

  String _normalizeReceiveCurrency(CryptoCurrency receiveCurrency) {
    switch (receiveCurrency) {
      case CryptoCurrency.eth:
        return 'eth';
      case CryptoCurrency.maticpoly:
        return 'polygon';
      default:
        return receiveCurrency.tag ?? '';
    }
  }

  Future<bool> _isExternallyOwnedAccountAddress(String receivingAddress) async {
    final normalizedReceiveCurrency = _normalizeReceiveCurrency(receiveCurrency);

    final isEOAAddress = !(await _isContractAddress(normalizedReceiveCurrency, receivingAddress));
    return isEOAAddress;
  }

  Future<bool> _isContractAddress(String chainName, String contractAddress) async {
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

      final decodedResponse = jsonDecode(response.body)[0] as Map<String, dynamic>;

      final name = decodedResponse['name'] as String?;

      bool isContractAddress = name!.isNotEmpty;

      return isContractAddress;
    } catch (e) {
      printV(e);
      return false;
    }
  }

  // Adding user's Erc20 tokens to the list of currencies

  @action
  Future<void> _injectUserEthTokensIntoCurrencyLists() async {
    final tokens = await TokenUtilities.loadEvmTokensForSwap();
    final toAddReceive = <CryptoCurrency>[];
    final toAddDeposit = <CryptoCurrency>[];

    for (final token in tokens) {
      if (!_listContainsToken(receiveCurrencies, token)) toAddReceive.add(token);
      if (!_listContainsToken(depositCurrencies, token)) toAddDeposit.add(token);
    }

    if (toAddReceive.isNotEmpty) receiveCurrencies.addAll(toAddReceive);
    if (toAddDeposit.isNotEmpty) depositCurrencies.addAll(toAddDeposit);
  }

  bool _listContainsToken(List<CryptoCurrency> list, Erc20Token token) {
    return list.any((item) {
      if (item is Erc20Token) {
        return item.contractAddress.toLowerCase() == token.contractAddress.toLowerCase();
      }
      return item.title.toUpperCase() == token.symbol.toUpperCase() &&
          (item.tag?.toUpperCase() == token.tag?.toUpperCase() || item.tag == null);
    });
  }

  // Adding user's Solana tokens to the list of currencies

  bool _listContainsSplToken(List<CryptoCurrency> list, SPLToken token) {
    return list.any((item) {
      if (item is SPLToken) {
        return item.mintAddress.toLowerCase() == token.mintAddress.toLowerCase();
      }
      return item.title.toUpperCase() == token.symbol.toUpperCase() &&
          (item.tag?.toUpperCase() == token.tag?.toUpperCase() || item.tag == null);
    });
  }

  @action
  Future<void> _injectUserSplTokensIntoCurrencyLists() async {
    final tokens = await TokenUtilities.loadSolTokensForSwap();
    final toAddReceive = <CryptoCurrency>[];
    final toAddDeposit = <CryptoCurrency>[];

    for (final token in tokens) {
      if (!_listContainsSplToken(receiveCurrencies, token)) toAddReceive.add(token);
      if (!_listContainsSplToken(depositCurrencies, token)) toAddDeposit.add(token);
    }

    if (toAddReceive.isNotEmpty) receiveCurrencies.addAll(toAddReceive);
    if (toAddDeposit.isNotEmpty) depositCurrencies.addAll(toAddDeposit);
  }

  // Adding user's Tron tokens to the list of currencies

  bool _listContainsTronToken(List<CryptoCurrency> list, TronToken token) {
    return list.any((item) {
      if (item is TronToken) {
        return item.contractAddress.toLowerCase() == token.contractAddress.toLowerCase();
      }
      return item.title.toUpperCase() == token.symbol.toUpperCase() &&
          (item.tag?.toUpperCase() == token.tag?.toUpperCase() || item.tag == null);
    });
  }

  @action
  Future<void> _injectUserTronTokensIntoCurrencyLists() async {
    final tokens = await TokenUtilities.loadTronTokensForSwap();
    final toAddReceive = <CryptoCurrency>[];
    final toAddDeposit = <CryptoCurrency>[];

    for (final token in tokens) {
      if (!_listContainsTronToken(receiveCurrencies, token)) toAddReceive.add(token);
      if (!_listContainsTronToken(depositCurrencies, token)) toAddDeposit.add(token);
    }

    if (toAddReceive.isNotEmpty) receiveCurrencies.addAll(toAddReceive);
    if (toAddDeposit.isNotEmpty) depositCurrencies.addAll(toAddDeposit);
  }

  double initialAmountByAssets(CryptoCurrency ticker) {
    final amount = switch (ticker) {
      CryptoCurrency.trx => 1000,
      CryptoCurrency.nano => 10,
      CryptoCurrency.zano => 10,
      CryptoCurrency.wow => 1000,
      CryptoCurrency.ada => 1000,
      CryptoCurrency.dash => 10,
      CryptoCurrency.rune => 10,
      _ => 1
    };
    return amount.toDouble();
  }
}
