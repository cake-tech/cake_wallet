import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'exchange_view_model.g.dart';

class ExchangeViewModel = ExchangeViewModelBase with _$ExchangeViewModel;

abstract class ExchangeViewModelBase extends WalletChangeListenerViewModel with Store {
  @override
  void onWalletChange(wallet) {
    receiveCurrency = wallet.currency;
    depositCurrency = wallet.currency;
  }

  ExchangeViewModelBase(
    AppStore appStore,
    this.trades,
    this._exchangeTemplateStore,
    this.tradesStore,
    this._settingsStore,
    this.sharedPreferences,
    this.contactListViewModel,
  )   : _cryptoNumberFormat = NumberFormat(),
        isFixedRateMode = false,
        isReceiveAmountEntered = false,
        depositAmount = '',
        receiveAmount = '',
        receiveAddress = '',
        depositAddress = '',
        isDepositAddressEnabled = false,
        isReceiveAmountEditable = false,
        _useTorOnly = false,
        receiveCurrencies = <CryptoCurrency>[],
        depositCurrencies = <CryptoCurrency>[],
        limits = Limits(min: 0, max: 0),
        tradeState = ExchangeTradeStateInitial(),
        limitsState = LimitsInitialState(),
        receiveCurrency = appStore.wallet!.currency,
        depositCurrency = appStore.wallet!.currency,
        providerList = [],
        selectedProviders = ObservableList<ExchangeProvider>(),
        super(appStore: appStore) {
    _useTorOnly = _settingsStore.exchangeStatus == ExchangeApiMode.torOnly;
    _setProviders();
    const excludeDepositCurrencies = [CryptoCurrency.btt];
    const excludeReceiveCurrencies = [
      CryptoCurrency.xlm,
      CryptoCurrency.xrp,
      CryptoCurrency.bnb,
      CryptoCurrency.btt
    ];
    _initialPairBasedOnWallet();

    final Map<String, dynamic> exchangeProvidersSelection =
        json.decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}")
            as Map<String, dynamic>;

    /// if the provider is not in the user settings (user's first time or newly added provider)
    /// then use its default value decided by us
    selectedProviders = ObservableList.of(providersForCurrentPair()
        .where((element) => exchangeProvidersSelection[element.title] == null
            ? element.isEnabled
            : (exchangeProvidersSelection[element.title] as bool))
        .toList());

    _setAvailableProviders();
    _calculateBestRate();

    bestRateSync = Timer.periodic(Duration(seconds: 10), (timer) => _calculateBestRate());

    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    depositAmount = '';
    receiveAmount = '';
    receiveAddress = '';
    depositAddress = depositCurrency == wallet.currency ? wallet.walletAddresses.address : '';
    provider = providersForCurrentPair().first;
    final initialProvider = provider;
    provider!.checkIsAvailable().then((bool isAvailable) {
      if (!isAvailable && provider == initialProvider) {
        provider = providerList.firstWhere((provider) => provider is ChangeNowExchangeProvider,
            orElse: () => providerList.last);
        _onPairChange();
      }
    });
    receiveCurrencies = CryptoCurrency.all
        .where((cryptoCurrency) => !excludeReceiveCurrencies.contains(cryptoCurrency))
        .toList();
    depositCurrencies = CryptoCurrency.all
        .where((cryptoCurrency) => !excludeDepositCurrencies.contains(cryptoCurrency))
        .toList();
    _defineIsReceiveAmountEditable();
    loadLimits();
    reaction((_) => isFixedRateMode, (Object _) {
      loadLimits();
      _bestRate = 0;
      _calculateBestRate();
    });
  }

  bool _useTorOnly;
  final Box<Trade> trades;
  final ExchangeTemplateStore _exchangeTemplateStore;
  final TradesStore tradesStore;
  final SharedPreferences sharedPreferences;

  List<ExchangeProvider> get _allProviders => [
        ChangeNowExchangeProvider(settingsStore: _settingsStore),
        SideShiftExchangeProvider(),
        SimpleSwapExchangeProvider(),
        TrocadorExchangeProvider(useTorOnly: _useTorOnly,
            providerStates: _settingsStore.trocadorProviderStates),
        if (FeatureFlag.isExolixEnabled) ExolixExchangeProvider(),
      ];

  @observable
  ExchangeProvider? provider;

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
  String depositAmount;

  @observable
  String receiveAmount;

  @observable
  String depositAddress;

  @observable
  String receiveAddress;

  @observable
  bool isDepositAddressEnabled;

  @observable
  bool isReceiveAmountEntered;

  @observable
  bool isReceiveAmountEditable;

  @observable
  bool isFixedRateMode;

  @observable
  Limits limits;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  ObservableList<ExchangeTemplate> get templates => _exchangeTemplateStore.templates;

  @computed
  List<WalletContact> get walletContactsToShow => contactListViewModel.walletContacts
      .where((element) => element.type == receiveCurrency)
      .toList();

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
  TransactionPriority get transactionPriority {
    final priority = _settingsStore.priority[wallet.type];

    if (priority == null) {
      throw Exception('Unexpected type ${wallet.type.toString()}');
    }

    return priority;
  }

  bool get hasAllAmount =>
      (wallet.type == WalletType.bitcoin ||
          wallet.type == WalletType.litecoin ||
          wallet.type == WalletType.bitcoinCash) &&
      depositCurrency == wallet.currency;

  bool get isMoneroWallet => wallet.type == WalletType.monero;

  bool get isLowFee {
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
        return transactionPriority == monero!.getMoneroTransactionPrioritySlow();
      case WalletType.bitcoin:
        return transactionPriority == bitcoin!.getBitcoinTransactionPrioritySlow();
      case WalletType.litecoin:
        return transactionPriority == bitcoin!.getLitecoinTransactionPrioritySlow();
      case WalletType.ethereum:
        return transactionPriority == ethereum!.getEthereumTransactionPrioritySlow();
      case WalletType.bitcoinCash:
        return transactionPriority == bitcoinCash!.getBitcoinCashTransactionPrioritySlow();
      case WalletType.polygon:
        return transactionPriority == polygon!.getPolygonTransactionPrioritySlow();
      default:
        return false;
    }
  }

  List<CryptoCurrency> receiveCurrencies;

  List<CryptoCurrency> depositCurrencies;

  final NumberFormat _cryptoNumberFormat;

  final SettingsStore _settingsStore;

  final ContactListViewModel contactListViewModel;

  double _bestRate = 0.0;

  late Timer bestRateSync;

  @action
  void changeDepositCurrency({required CryptoCurrency currency}) {
    depositCurrency = currency;
    isFixedRateMode = false;
    _onPairChange();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
  }

  @action
  void changeReceiveCurrency({required CryptoCurrency currency}) {
    receiveCurrency = currency;
    isFixedRateMode = false;
    _onPairChange();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
  }

  @action
  Future<void> changeReceiveAmount({required String amount}) async {
    receiveAmount = amount;

    if (amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _enteredAmount = double.tryParse(amount.replaceAll(',', '.')) ?? 0;

    if (_bestRate == 0) {
      depositAmount = S.current.fetching;

      await _calculateBestRate();
    }
    _cryptoNumberFormat.maximumFractionDigits = depositMaxDigits;

    depositAmount = _cryptoNumberFormat
        .format(_enteredAmount / _bestRate)
        .toString()
        .replaceAll(RegExp('\\,'), '');
  }

  @action
  Future<void> changeDepositAmount({required String amount}) async {
    depositAmount = amount;

    if (amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _enteredAmount = double.tryParse(amount.replaceAll(',', '.')) ?? 0;

    /// in case the best rate was not calculated yet
    if (_bestRate == 0) {
      receiveAmount = S.current.fetching;

      await _calculateBestRate();
    }
    _cryptoNumberFormat.maximumFractionDigits = receiveMaxDigits;

    receiveAmount = _cryptoNumberFormat
        .format(_bestRate * _enteredAmount)
        .toString()
        .replaceAll(RegExp('\\,'), '');
  }

  bool checkIfInputMeetsMinOrMaxCondition(String input) {
    final _enteredAmount = double.tryParse(input.replaceAll(',', '.')) ?? 0;
    double minLimit = limits.min ?? 0;
    double? maxLimit = limits.max;

    if (_enteredAmount < minLimit) return false;

    if (maxLimit != null && _enteredAmount > maxLimit) return false;

    return true;
  }

  Future<void> _calculateBestRate() async {
    final amount = double.tryParse(isFixedRateMode ? receiveAmount : depositAmount) ?? 1;

    final _providers = _tradeAvailableProviders
        .where((element) => !isFixedRateMode || element.supportsFixedRate)
        .toList();

    final result = await Future.wait<double>(_providers.map((element) => element.fetchRate(
        from: depositCurrency,
        to: receiveCurrency,
        amount: amount,
        isFixedRateMode: isFixedRateMode,
        isReceiveAmount: isFixedRateMode)));

    _sortedAvailableProviders.clear();

    for (int i = 0; i < result.length; i++) {
      if (result[i] != 0) {
        /// add this provider as its valid for this trade
        try {
          _sortedAvailableProviders[result[i]] = _providers[i];
        } catch (e) {
          // will throw "Concurrent modification during iteration" error if modified at the same
          // time [createTrade] is called, as this is not a normal map, but a sorted map
        }
      }
    }
    if (_sortedAvailableProviders.isNotEmpty) _bestRate = _sortedAvailableProviders.keys.first;
  }

  @action
  Future<void> loadLimits() async {
    if (selectedProviders.isEmpty) return;

    limitsState = LimitsIsLoading();

    final from = isFixedRateMode ? receiveCurrency : depositCurrency;
    final to = isFixedRateMode ? depositCurrency : receiveCurrency;

    double? lowestMin = double.maxFinite;
    double? highestMax = 0.0;

    try {
      for (var provider in selectedProviders) {
        /// if this provider is not valid for the current pair, skip it
        if (!providersForCurrentPair().contains(provider)) continue;

        try {
          final tempLimits =
              await provider.fetchLimits(from: from, to: to, isFixedRateMode: isFixedRateMode);

          if (lowestMin != null && (tempLimits.min ?? -1) < lowestMin) lowestMin = tempLimits.min;

          if (highestMax != null && (tempLimits.max ?? double.maxFinite) > highestMax)
            highestMax = tempLimits.max;
        } catch (e) {
          continue;
        }
      }
    } on ConcurrentModificationError {
      /// if user changed the selected providers while fetching limits
      /// then delay the fetching limits a bit and try again
      ///
      /// this is because the limitation of collections that
      /// you can't modify it while iterating through it
      Future.delayed(Duration(milliseconds: 200), loadLimits);
    }

    if (lowestMin != double.maxFinite) {
      limits = Limits(min: lowestMin, max: highestMax);

      limitsState = LimitsLoadedSuccessfully(limits: limits);
    } else {
      limitsState = LimitsLoadedFailure(error: 'Limits loading failed');
    }
  }

  @action
  Future<void> createTrade() async {
    try {
      for (var provider in _sortedAvailableProviders.values) {
        if (!(await provider.checkIsAvailable())) continue;

        final request = TradeRequest(
            fromCurrency: depositCurrency,
            toCurrency: receiveCurrency,
            fromAmount: depositAmount.replaceAll(',', '.'),
            toAmount: receiveAmount.replaceAll(',', '.'),
            refundAddress: depositAddress,
            toAddress: receiveAddress,
            isFixedRate: isFixedRateMode);

        var amount = isFixedRateMode ? receiveAmount : depositAmount;
        amount = amount.replaceAll(',', '.');

        if (limitsState is LimitsLoadedSuccessfully) {
          if (double.tryParse(amount) == null) continue;

          if (limits.max != null && double.parse(amount) < limits.min!)
            continue;
          else if (limits.max != null && double.parse(amount) > limits.max!)
            continue;
          else {
            try {
              tradeState = TradeIsCreating();
              final trade =
                  await provider.createTrade(request: request, isFixedRateMode: isFixedRateMode);
              trade.walletId = wallet.id;
              trade.fromWalletAddress = wallet.walletAddresses.address;
              tradesStore.setTrade(trade);
              await trades.add(trade);
              tradeState = TradeIsCreatedSuccessfully(trade: trade);

              /// return after the first successful trade
              return;
            } catch (e) {
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
    depositAmount = '';
    receiveAmount = '';
    depositAddress = depositCurrency == wallet.currency ? wallet.walletAddresses.address : '';
    receiveAddress = receiveCurrency == wallet.currency ? wallet.walletAddresses.address : '';
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isFixedRateMode = false;
    _onPairChange();
  }

  @action
  void calculateDepositAllAmount() {
    if (wallet.type == WalletType.bitcoin ||
        wallet.type == WalletType.litecoin ||
        wallet.type == WalletType.bitcoinCash) {
      final availableBalance = wallet.balance[wallet.currency]!.available;
      final priority = _settingsStore.priority[wallet.type]!;
      final fee = wallet.calculateEstimatedFee(priority, null);

      if (availableBalance < fee || availableBalance == 0) return;

      final amount = availableBalance - fee;
      changeDepositAmount(amount: bitcoin!.formatterBitcoinAmountToString(amount: amount));
    }
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

  List<ExchangeProvider> providersForCurrentPair() =>
      _providersForPair(from: depositCurrency, to: receiveCurrency);

  List<ExchangeProvider> _providersForPair(
          {required CryptoCurrency from, required CryptoCurrency to}) =>
      providerList
          .where((provider) =>
              provider.pairList.where((pair) => pair.from == from && pair.to == to).isNotEmpty)
          .toList();

  void _onPairChange() {
    depositAmount = '';
    receiveAmount = '';
    loadLimits();
    _setAvailableProviders();
    _bestRate = 0;
    _calculateBestRate();
  }

  void _initialPairBasedOnWallet() {
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
      case WalletType.polygon:
        depositCurrency = CryptoCurrency.maticpoly;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.solana:
        depositCurrency = CryptoCurrency.sol;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      default:
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
    selectedProviders.add(provider);
    if (providersForCurrentPair().contains(provider)) _tradeAvailableProviders.add(provider);
  }

  @action
  void removeExchangeProvider(ExchangeProvider provider) {
    selectedProviders.remove(provider);
    _tradeAvailableProviders.remove(provider);
  }

  @action
  void saveSelectedProviders() {
    depositAmount = '';
    receiveAmount = '';
    isFixedRateMode = false;
    _defineIsReceiveAmountEditable();
    loadLimits();
    _bestRate = 0;
    _calculateBestRate();

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

  bool get isAvailableInSelected {
    final providersForPair = providersForCurrentPair();
    return selectedProviders
        .any((element) => element.isAvailable && providersForPair.contains(element));
  }

  void _setAvailableProviders() {
    _tradeAvailableProviders.clear();

    _tradeAvailableProviders.addAll(
        selectedProviders.where((provider) => providersForCurrentPair().contains(provider)));
  }

  @action
  void setDefaultTransactionPriority() {
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
        _settingsStore.priority[wallet.type] = monero!.getMoneroTransactionPriorityAutomatic();
        break;
      case WalletType.bitcoin:
        _settingsStore.priority[wallet.type] = bitcoin!.getBitcoinTransactionPriorityMedium();
        break;
      case WalletType.litecoin:
        _settingsStore.priority[wallet.type] = bitcoin!.getLitecoinTransactionPriorityMedium();
        break;
      case WalletType.ethereum:
        _settingsStore.priority[wallet.type] = ethereum!.getDefaultTransactionPriority();
        break;
      case WalletType.bitcoinCash:
        _settingsStore.priority[wallet.type] = bitcoinCash!.getDefaultTransactionPriority();
        break;
      case WalletType.polygon:
        _settingsStore.priority[wallet.type] = polygon!.getDefaultTransactionPriority();
        break;
      default:
        break;
    }
  }

  void _setProviders() {
    if (_settingsStore.exchangeStatus == ExchangeApiMode.torOnly)
      providerList = _allProviders.where((provider) => provider.supportsOnionAddress).toList();
    else
      providerList = _allProviders;
  }

  int get depositMaxDigits => depositCurrency.decimals;

  int get receiveMaxDigits => receiveCurrency.decimals;
}
