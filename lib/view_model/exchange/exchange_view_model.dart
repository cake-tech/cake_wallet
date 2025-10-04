import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/create_trade_result.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
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
import 'package:cake_wallet/exchange/provider/letsexchange_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/stealth_ex_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swaptrade_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/xoswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/token_utilities.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/tron_token.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_info.dart';
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
    this.unspentCoinsListViewModel,
    this.feesViewModel,
    this.walletInfoSource,
    this.fiatConversionStore,
  )   : _cryptoNumberFormat = NumberFormat(),
        isSendAllEnabled = false,
        isFixedRateMode = false,
        isReceiveAmountEntered = false,
        depositAmount = '',
        receiveAmount = '',
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

    unspentCoinsListViewModel.initialSetup().then((_) {
      unspentCoinsListViewModel.resetUnspentCoinsInfoSelections();
    });

    final Map<String, dynamic> exchangeProvidersSelection =
        json.decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}")
            as Map<String, dynamic>;

    /// if the provider is not in the user settings (user's first time or newly added provider)
    /// then use its default value decided by us
    selectedProviders = ObservableList.of(providerList
        .where((element) => exchangeProvidersSelection[element.title] == null
            ? element.isEnabled
            : (exchangeProvidersSelection[element.title] as bool))
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
        calculateBestRate();
      }
    });

    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    depositAmount = '';
    receiveAmount = '';
    receiveAddress = '';
    depositAddress =
        depositCurrency == wallet.currency ? wallet.walletAddresses.addressForExchange : '';

    provider = providerList.firstOrNull;
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
    reaction((_) => isFixedRateMode, (Object _) {
      bestRate = 0.0;
      loadLimits();
    });

    if (isElectrumWallet) {
      bitcoin!.updateFeeRates(wallet);
    }
  }

  bool get isElectrumWallet => [
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.bitcoinCash,
        WalletType.dogecoin
      ].contains(wallet.type);

  bool get hideAddressAfterExchange =>
      [WalletType.monero, WalletType.wownero].contains(wallet.type);

  bool _useTorOnly;
  final Box<Trade> trades;
  final ExchangeTemplateStore _exchangeTemplateStore;
  final TradesStore tradesStore;
  final SharedPreferences sharedPreferences;

  List<ExchangeProvider> get _allProviders => [
        ChangeNowExchangeProvider(settingsStore: _settingsStore),
        SideShiftExchangeProvider(),
        ChainflipExchangeProvider(tradesStore: trades),
        if (FeatureFlag.isExolixEnabled) ExolixExchangeProvider(),
        SwapTradeExchangeProvider(),
        LetsExchangeExchangeProvider(),
        StealthExExchangeProvider(),
        XOSwapExchangeProvider(),
        TrocadorExchangeProvider(
            useTorOnly: _useTorOnly, providerStates: _settingsStore.trocadorProviderStates),
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

  Map<ExchangeProvider, Limits> _providerLimits = {};

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
  bool isSendAllEnabled;

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
      [
        WalletType.monero,
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.bitcoinCash,
        WalletType.dogecoin,
      ].contains(wallet.type) &&
      depositCurrency == wallet.currency;

  bool get isMoneroWallet => wallet.type == WalletType.monero;

  @observable
  ObservableList<CryptoCurrency> receiveCurrencies;

  @observable
  ObservableList<CryptoCurrency> depositCurrencies;

  final NumberFormat _cryptoNumberFormat;

  final SettingsStore _settingsStore;

  final ContactListViewModel contactListViewModel;

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  final FeesViewModel feesViewModel;

  final Box<WalletInfo> walletInfoSource;

  @observable
  double bestRate = 0.0;

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
      if (receiveAmount.isNotEmpty) {
        if (fiatConversionStore.prices[receiveCurrency] == null) return '';

        amount = calculateFiatAmount(
          price: fiatConversionStore.prices[receiveCurrency]!,
          cryptoAmount: receiveAmount,
        );
      }
    } catch (_) {
      log('Error calculating receive amount fiat formatted: $_');
    }
    return isFiatDisabled ? '' : '$amount';
  }

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

    if (bestRate == 0) {
      depositAmount = S.current.fetching;

      await calculateBestRate();
    }

    _cryptoNumberFormat.maximumFractionDigits = depositMaxDigits;

    depositAmount = _cryptoNumberFormat
        .format(_enteredAmount / bestRate)
        .toString()
        .replaceAll(RegExp('\\,'), '');
  }

  @action
  void setReceiveAmountFromFiat({required String fiatAmount}) {
    final _enteredAmount = double.tryParse(fiatAmount.replaceAll(',', '.')) ?? 0.0;
    final crypto = _enteredAmount / fiatConversionStore.prices[receiveCurrency]!;
    final receiveAmountTmp = _cryptoNumberFormat.format(crypto);
    if (receiveAmount != receiveAmountTmp) {
      changeReceiveAmount(amount: receiveAmountTmp);
    }
  }

  @action
  Future<void> changeDepositAmount({required String amount}) async {
    depositAmount = amount;

    if (amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    /// For fixed-rate transactions, we don't want to recalculate receive amount
    /// as it should remain exactly what the user set
    if (isFixedRateMode) return;

    final _enteredAmount = double.tryParse(amount.replaceAll(',', '.')) ?? 0;

    /// in case the best rate was not calculated yet
    if (bestRate == 0) {
      receiveAmount = S.current.fetching;

      await calculateBestRate();
    }

    _cryptoNumberFormat.maximumFractionDigits = receiveMaxDigits;

    receiveAmount = _cryptoNumberFormat
        .format(bestRate * _enteredAmount)
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

  Future<void> calculateBestRate() async {
    if (depositCurrency == receiveCurrency) {
      bestRate = 0.0;
      return;
    }
    final amount = double.tryParse(isFixedRateMode ? receiveAmount : depositAmount) ??
        initialAmountByAssets(isFixedRateMode ? receiveCurrency : depositCurrency);

    final validProvidersForAmount = _tradeAvailableProviders.where((provider) {
      final limits = _providerLimits[provider];

      if (limits == null) return false;
      if (limits.min != null && amount < limits.min!) return false;
      if (limits.max != null && amount > limits.max!) return false;

      return true;
    }).toList();

    final _providers = validProvidersForAmount
        .where((element) => !isFixedRateMode || element.supportsFixedRate)
        .toList();

    final result = await Future.wait<double>(
      _providers.map(
        (element) => element
            .fetchRate(
              from: depositCurrency,
              to: receiveCurrency,
              amount: amount,
              isFixedRateMode: isFixedRateMode,
              isReceiveAmount: isFixedRateMode,
            )
            .timeout(
              Duration(seconds: 7),
              onTimeout: () => 0.0,
            ),
      ),
    );

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
      }
    }

    // Replace the old map with the new one
    _sortedAvailableProviders.clear();
    _sortedAvailableProviders.addAll(newSortedProviders);

    if (_sortedAvailableProviders.isNotEmpty) bestRate = _sortedAvailableProviders.keys.first;
  }

  @action
  Future<void> loadLimits() async {
    if (depositCurrency == receiveCurrency) {
      limitsState = LimitsLoadedSuccessfully(limits: Limits(min: 0, max: 0));
      return;
    }
    if (selectedProviders.isEmpty) return;

    limitsState = LimitsIsLoading();

    final from = isFixedRateMode ? receiveCurrency : depositCurrency;
    final to = isFixedRateMode ? depositCurrency : receiveCurrency;

    double? lowestMin = double.maxFinite;
    double? highestMax = 0.0;

    try {
      final futures = selectedProviders
          .where((provider) => providerList.contains(provider))
          .map((provider) async {
        final limits = await provider
            .fetchLimits(
              from: from,
              to: to,
              isFixedRateMode: isFixedRateMode,
            )
            .onError((error, stackTrace) => Limits(max: 0.0, min: double.maxFinite))
            .timeout(
              Duration(seconds: 7),
              onTimeout: () => Limits(max: 0.0, min: double.maxFinite),
            );
        return MapEntry(provider, limits);
      }).toList();

      final entries = await Future.wait(futures);
      _providerLimits = Map.fromEntries(entries);

      _providerLimits.values.forEach((tempLimits) {
        if (lowestMin != null && (tempLimits.min ?? -1) < lowestMin!) {
          lowestMin = tempLimits.min;
        }

        if (highestMax != null && (tempLimits.max ?? double.maxFinite) > highestMax!) {
          highestMax = tempLimits.max;
        }
      });
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

    calculateBestRate();
  }

  @action
  Future<void> createTrade() async {
    if (depositCurrency == receiveCurrency) {
      tradeState = TradeIsCreatedFailure(
          title: S.current.trade_not_created, error: 'Can\'t exchange the same currency');
      return;
    }
    if (isSendAllEnabled) {
      await calculateDepositAllAmount();
      final amount = double.tryParse(depositAmount);

      if (limits.min != null && amount != null && amount < limits.min!) {
        tradeState = TradeIsCreatedFailure(
            title: S.current.trade_not_created,
            error: S.current.amount_is_below_minimum_limit(limits.min!.toString()));
        return;
      }
    }

    // Ensure we have providers available before attempting to create trade
    if (_sortedAvailableProviders.isEmpty) {
      await calculateBestRate();

      if (_sortedAvailableProviders.isEmpty) {
        tradeState = TradeIsCreatedFailure(
            title: S.current.trade_not_created,
            error: S.current.none_of_selected_providers_can_exchange);
        return;
      }
    }

    try {
      // snapshot of providers to avoid concurrent modification issues
      final providersSnapshot = _sortedAvailableProviders.values.toList();
      final ratesSnapshot = _sortedAvailableProviders.keys.toList();

      for (var i = 0; i < providersSnapshot.length; i++) {
        final provider = providersSnapshot[i];
        final providerRate = ratesSnapshot[i];

        if (!(await provider.checkIsAvailable())) continue;

        bestRate = providerRate;
        await changeDepositAmount(amount: depositAmount);

        final request = TradeRequest(
          fromCurrency: depositCurrency,
          toCurrency: receiveCurrency,
          fromAmount: depositAmount.replaceAll(',', '.'),
          toAmount: receiveAmount.replaceAll(',', '.'),
          refundAddress: depositAddress,
          toAddress: receiveAddress,
          isFixedRate: isFixedRateMode,
        );

        if (hideAddressAfterExchange) {
          wallet.walletAddresses.hiddenAddresses.add(depositAddress);
          await wallet.walletAddresses.saveAddressesInBox();
        }

        var amount = isFixedRateMode ? receiveAmount : depositAmount;
        amount = amount.replaceAll(',', '.');

        if (limitsState is LimitsLoadedSuccessfully) {
          if (double.tryParse(amount) == null) continue;

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
              trade.fromWalletAddress = wallet.walletAddresses.address;

              final canCreateTrade = await isCanCreateTrade(trade);
              if (!canCreateTrade.result) {
                tradeState = TradeIsCreatedFailure(
                  title: S.current.trade_not_created,
                  error: canCreateTrade.errorMessage ?? '',
                );
                return;
              }

              tradesStore.setTrade(trade);
              if (trade.provider != ExchangeProviderDescription.thorChain) await trades.add(trade);
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
    depositAddress =
        depositCurrency == wallet.currency ? wallet.walletAddresses.addressForExchange : '';
    receiveAddress =
        receiveCurrency == wallet.currency ? wallet.walletAddresses.addressForExchange : '';
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
    if ([
      WalletType.litecoin,
      WalletType.bitcoin,
      WalletType.bitcoinCash,
      WalletType.dogecoin,
    ].contains(wallet.type)) {
      final priority = _settingsStore.priority[wallet.type]!;

      final amount = await bitcoin!.estimateFakeSendAllTxAmount(
        wallet,
        priority,
        coinTypeToSpendFrom:
            wallet.type == WalletType.litecoin ? UnspentCoinType.nonMweb : UnspentCoinType.any,
      );

      changeDepositAmount(amount: wallet.formatCryptoAmount(amount.toString()));
    } else if (wallet.type == WalletType.monero) {
      final amount = await unspentCoinsListViewModel.getSendingBalance(UnspentCoinType.any);

      changeDepositAmount(amount: wallet.formatCryptoAmount(amount.toString()));
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

  void _onPairChange() {
    depositAmount = '';
    receiveAmount = '';
    bestRate = 0.0;
    loadLimits();
    _setAvailableProviders();
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
    selectedProviders.add(provider);
    if (providerList.contains(provider)) _tradeAvailableProviders.add(provider);
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
    final userTokens = await TokenUtilities.loadAllUniqueEvmTokens(walletInfoSource);

    final toAddReceive = <CryptoCurrency>[];
    final toAddDeposit = <CryptoCurrency>[];

    for (final token in userTokens) {
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
    final userTokens = await TokenUtilities.loadAllUniqueSolTokens(walletInfoSource);

    final toAddReceive = <CryptoCurrency>[];
    final toAddDeposit = <CryptoCurrency>[];

    for (final token in userTokens) {
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
    final userTokens = await TokenUtilities.loadAllUniqueTronTokens(walletInfoSource);

    final toAddReceive = <CryptoCurrency>[];
    final toAddDeposit = <CryptoCurrency>[];

    for (final token in userTokens) {
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
