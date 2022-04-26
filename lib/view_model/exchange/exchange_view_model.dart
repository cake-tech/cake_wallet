import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/exchange/provider_rate_state.dart';
import 'package:cake_wallet/exchange/selected_exchange_provider.dart';
import 'package:cake_wallet/store/selected_exchange_provider_store.dart';
import 'package:cake_wallet/view_model/exchange/provider_rate.dart';
import 'package:cake_wallet/exchange/sideshift/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/sideshift/sideshift_request.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/changenow/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/changenow/changenow_request.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_trade_request.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_request.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'exchange_view_model.g.dart';

class ExchangeViewModel = ExchangeViewModelBase with _$ExchangeViewModel;

abstract class ExchangeViewModelBase with Store {
  ExchangeViewModelBase(this.wallet, this.trades, this._exchangeTemplateStore,
      this.tradesStore, this._settingsStore, this._selectedExchangeProviderStore, 
      this.sharedPreferences) {
    const excludeDepositCurrencies = [CryptoCurrency.xhv];
    const excludeReceiveCurrencies = [CryptoCurrency.xlm, CryptoCurrency.xrp, CryptoCurrency.bnb, CryptoCurrency.xhv];
    providerList = [ChangeNowExchangeProvider() ,SideShiftExchangeProvider()];
    _initialPairBasedOnWallet();
    _storeDefaultProviders();
    _onPairChange();      
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
    depositAmount = '';
    receiveAmount = '';
    receiveAddress = '';
    depositAddress = depositCurrency == wallet.currency
        ? wallet.walletAddresses.address : '';
    limitsState = LimitsInitialState();
    ratesState = RateInitialState();
    tradeState = ExchangeTradeStateInitial();
    _cryptoNumberFormat = NumberFormat()..maximumFractionDigits = 12;
    _isProvidersForCurrentPair();
    _loadAvailableProviders();
    receiveCurrencies = CryptoCurrency.all
      .where((cryptoCurrency) => !excludeReceiveCurrencies.contains(cryptoCurrency))
      .toList();
    depositCurrencies = CryptoCurrency.all
      .where((cryptoCurrency) => !excludeDepositCurrencies.contains(cryptoCurrency))
      .toList();
    isReverse = false;
    isFixedRateMode = false;
    isReceiveAmountEntered = false;
    _loadRates();
    _defineIsReceiveAmountEditable();
  }

  final WalletBase wallet;
  final Box<Trade> trades;
  final ExchangeTemplateStore _exchangeTemplateStore;
  final SelectedExchangeProviderStore _selectedExchangeProviderStore;
  final TradesStore tradesStore;
  
  @observable
  ExchangeProvider provider;

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
  bool isReceiveAddressEnabled;

  @observable
  bool isReceiveAmountEntered;

  @observable
  bool isReceiveAmountEditable;

  @observable
  bool isFixedRateMode;

  @observable
  bool isProvidersForPair;

  @computed
  String get providerTitle => selectedExchangeProviders.length == 1 ? selectedExchangeProviders.first.provider : 'AUTOMATIC';

  @computed
  List<String> get savedProvidersTitle  => selectedExchangeProviders.map((e) => e.provider).toList();

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  ObservableList<ExchangeTemplate> get templates =>
      _exchangeTemplateStore.templates;

   @computed
  ObservableList<SelectedExchangeProvider> get selectedExchangeProviders =>
      _selectedExchangeProviderStore.selectedProviders;

  bool get hasAllAmount =>
      wallet.type == WalletType.bitcoin && depositCurrency == wallet.currency;

  bool get isMoneroWallet  => wallet.type == WalletType.monero;

  List<CryptoCurrency> receiveCurrencies;

  List<ProviderRate> providerRates = [];

  List<ExchangeProvider> _availableProviders = [];

  List<CryptoCurrency> depositCurrencies;

  Limits limits;

  bool isReverse;

  NumberFormat _cryptoNumberFormat;

  SettingsStore _settingsStore;

  SharedPreferences sharedPreferences;

  ProviderRateState ratesState;


  @action
  void selectProvider({ExchangeProvider provider, bool select}) {
    if(select){
    _selectedExchangeProviderStore.selectProvider(provider: provider);
    }else{
    final result  = selectedExchangeProviders.where((e) => e.provider == provider.title);
    _selectedExchangeProviderStore.remove(provider: result.first);
   _selectedExchangeProviderStore.update();
    }
    _isProvidersForCurrentPair();
  }

  @action
  void changeDepositCurrency({CryptoCurrency currency}) {
    depositCurrency = currency;
    isFixedRateMode = false;
    _onPairChange();
    _loadRates();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
  }

  @action
  void changeReceiveCurrency({CryptoCurrency currency}) {
    receiveCurrency = currency;
    isFixedRateMode = false;
    _onPairChange();
    _loadRates();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
  }

  @action
  void changeReceiveAmount({String amount}) {
    receiveAmount = amount;
    isReverse = true;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _amount = double.parse(amount.replaceAll(',', '.')) ?? 0;

    calculateAmount(_amount, true);
  }

  @action
  void changeDepositAmount({String amount}) {
    depositAmount = amount;
    isReverse = false;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _amount = double.parse(amount.replaceAll(',', '.')) ?? 0;
    calculateAmount(_amount, false);
  }
  
  void _isProvidersForCurrentPair() {
    final providers = providerList
        .where((provider) => provider.pairList
            .where((pair) =>
                pair.from == depositCurrency && pair.to == receiveCurrency)
            .isNotEmpty)
        .toList();

    isProvidersForPair = providers.isNotEmpty;
  }
  
  Future<void> _loadRates() async {
    final List<ProviderRate> rates = [];
    ratesState = RateIsLoading();

    await Future.forEach(providerList, (ExchangeProvider provider) async {
      if (isSelected(provider)) {
        try {
          final from = isFixedRateMode ? receiveCurrency : depositCurrency;
          final to = isFixedRateMode ? depositCurrency : receiveCurrency;
          final rate = await provider.fetchExchangeRate(from: from, to: to);
          rates.add(ProviderRate(rate: rate, provider: provider));
        } catch (e) {
          print(e);
        }
      }
    });

    if (rates.isNotEmpty) {
      rates.sort((a, b) => b.rate.compareTo(a.rate));
      providerRates = rates;
    }

    ratesState = RateInitialState();
  }

  Future<void> _getLimit() async {
    final List<Map<String, dynamic>> results = [];
    limitsState = LimitsIsLoading();

    await Future.forEach(providerRates, (ProviderRate providerRate) async {
      final _provider = providerRate.provider;

      if (isSelected(_provider)) {
        try {
          final from = isFixedRateMode ? receiveCurrency : depositCurrency;
          final to = isFixedRateMode ? depositCurrency : receiveCurrency;
          final _limit = await _provider.fetchLimits(
              from: from, to: to, isFixedRateMode: isFixedRateMode);
          results.add( <String, dynamic>{
            'hasError': false,
            'provider': _provider,
            'limit': _limit
          });
        } catch (e) {
          limitsState = LimitsLoadedFailure(error: e.toString());
        }
      }
    });
    
    final providersInRange = results.where((element) => _filterProvider(element)).toList();
    
    if(providersInRange.isNotEmpty){
      provider = providersInRange.first['provider'] as ExchangeProvider;
       limits = providersInRange.first['limit'] as Limits; 
      limitsState = LimitsLoadedSuccessfully(limits: limits);
      return;
    }
    if(results.isNotEmpty){
       limits = results.first['limit'] as Limits;
      limitsState = LimitsLoadedSuccessfully(limits: limits);
      return;
    }
    limitsState = LimitsLoadedFailure(error: 'amount is not within limits');
  }

  Future<void> calculateAmount(double amount, bool isReversed) async {
    if (ratesState is RateInitialState) {
      await _getLimit();
      final from = isReversed ? receiveCurrency : depositCurrency;
      final to = isReversed ? depositCurrency : receiveCurrency;
        if(provider == null) return;
        final result = await provider.calculateAmount(
            from: from,
            to: to,
            amount: amount,
            isFixedRateMode: isFixedRateMode,
            isReceiveAmount: isReversed);

        final formattedAmount = _cryptoNumberFormat
            .format(result)
            .toString()
            .replaceAll(RegExp('\\,'), '');

        if (isReversed) {
          depositAmount = formattedAmount;
        } else {
          receiveAmount = formattedAmount;
        }
      }
  }

  @action
  Future createTrade() async {
    TradeRequest request;
    String amount;
    CryptoCurrency currency;

     if (provider is SideShiftExchangeProvider) {
      request = SideShiftRequest(
          depositMethod: depositCurrency,
          settleMethod: receiveCurrency,
          depositAmount: depositAmount?.replaceAll(',', '.'),
          settleAddress: receiveAddress,
          refundAddress: depositAddress,
          );
      amount = depositAmount;
      currency = depositCurrency;
    }

    if (provider is XMRTOExchangeProvider) {
      request = XMRTOTradeRequest(
          from: depositCurrency,
          to: receiveCurrency,
          amount: depositAmount?.replaceAll(',', '.'),
          receiveAmount: receiveAmount?.replaceAll(',', '.'),
          address: receiveAddress,
          refundAddress: depositAddress,
          isBTCRequest: isReceiveAmountEntered);
      amount = depositAmount;
      currency = depositCurrency;
    }

    if (provider is ChangeNowExchangeProvider) {
      request = ChangeNowRequest(
          from: depositCurrency,
          to: receiveCurrency,
          fromAmount: depositAmount?.replaceAll(',', '.'),
          toAmount: receiveAmount?.replaceAll(',', '.'),
          refundAddress: depositAddress,
          address: receiveAddress,
          isReverse: isReverse);
      amount = isReverse ? receiveAmount : depositAmount;
      currency = depositCurrency;
    }

    if (provider is MorphTokenExchangeProvider) {
      request = MorphTokenRequest(
          from: depositCurrency,
          to: receiveCurrency,
          amount: depositAmount?.replaceAll(',', '.'),
          refundAddress: depositAddress,
          address: receiveAddress);
      amount = depositAmount;
      currency = depositCurrency;
    }

    amount = amount.replaceAll(',', '.');

    if (limitsState is LimitsLoadedSuccessfully && amount != null) {
      if (double.parse(amount) < limits.min) {
        tradeState = TradeIsCreatedFailure(
            title: provider.title,
            error: S.current.error_text_minimal_limit('${provider.description}',
                '${limits.min}', currency.toString()));
      } else if (limits.max != null && double.parse(amount) > limits.max) {
        tradeState = TradeIsCreatedFailure(
            title: provider.title,
            error: S.current.error_text_maximum_limit('${provider.description}',
                '${limits.max}', currency.toString()));
      } else {
        try {
          tradeState = TradeIsCreating();
          final trade = await provider.createTrade(
              request: request, isFixedRateMode: isFixedRateMode);
          trade.walletId = wallet.id;
          tradesStore.setTrade(trade);
          await trades.add(trade);
          tradeState = TradeIsCreatedSuccessfully(trade: trade);
        } catch (e) {
          tradeState =
              TradeIsCreatedFailure(title: provider.title, error: e.toString());
        }
      }
    } else {
      tradeState = TradeIsCreatedFailure(
          title: provider.title,
          error: S.current
              .error_text_limits_loading_failed('${provider.description}'));
    }
  }

  @action
  void reset() {
    _initialPairBasedOnWallet();
    isReceiveAmountEntered = false;
    depositAmount = '';
    receiveAmount = '';
    depositAddress = depositCurrency == wallet.currency
        ? wallet.walletAddresses.address : '';
    receiveAddress = receiveCurrency == wallet.currency
        ? wallet.walletAddresses.address : '';
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
    isFixedRateMode = false;
    _onPairChange();
  }

  @action
  void calculateDepositAllAmount() {
    if (wallet.type == WalletType.bitcoin) {
      final availableBalance = wallet.balance[wallet.currency].available;
      final priority = _settingsStore.priority[wallet.type];
      final fee = wallet.calculateEstimatedFee(priority, null);

      if (availableBalance < fee || availableBalance == 0) {
        return;
      }

      final amount = availableBalance - fee;
      changeDepositAmount(amount: bitcoin.formatterBitcoinAmountToString(amount: amount));
    }
  }

  void updateTemplate() => _exchangeTemplateStore.update();

  void addTemplate(
          {String amount,
          String depositCurrency,
          String receiveCurrency,
          String provider,
          String depositAddress,
          String receiveAddress}) =>
      _exchangeTemplateStore.addTemplate(
          amount: amount,
          depositCurrency: depositCurrency,
          receiveCurrency: receiveCurrency,
          provider: provider,
          depositAddress: depositAddress,
          receiveAddress: receiveAddress);

  void removeTemplate({ExchangeTemplate template}) =>
      _exchangeTemplateStore.remove(template: template);


  bool isPairUnavailable(dynamic exchangeProvider){
    final provider = exchangeProvider as ExchangeProvider;
    return isProviderUnavailable(provider) || provider.pairList
            .where((pair) =>
                pair.from == depositCurrency && pair.to == receiveCurrency)
            .isEmpty;
  }

  bool isProviderUnavailable(dynamic exchangeProvider){
     final provider = exchangeProvider as ExchangeProvider;
   return _availableProviders.where((e) => e.description == provider.description ).isEmpty;
  }
 
  void _loadAvailableProviders()async{
    await Future.forEach(providerList, (ExchangeProvider provider) async { 
       final available = await provider.checkIsAvailable();
       if(available) _availableProviders.add(provider);
    });
  }
  

  void _onPairChange() {
      _isProvidersForCurrentPair();
      depositAmount = '';
      receiveAmount = '';
  }

  void _storeDefaultProviders(){
     final savedDefaults = sharedPreferences.getBool(PreferencesKey.savedDefaultExchangeProviders) ?? false;
     final enabledProviders = providerList.where((e) => e.isEnabled ?? false).toList();
     if(!savedDefaults){
       for (var i = 0; i < enabledProviders.length; i++) {
         selectProvider(provider: enabledProviders[i], select: true);
       }
       sharedPreferences.setBool(PreferencesKey.savedDefaultExchangeProviders, true);
     }
  }


  bool isSelected(ExchangeProvider provider){
    final selected = savedProvidersTitle.contains(provider.title) ?? false;
    return selected;
  }

  bool _filterProvider(Map<String, dynamic> result){
    final limit = result['limit'] as Limits;
    final _provider = result['provider'] as ExchangeProvider;
    final amount = depositAmount;
    final _amount = double.parse(amount.replaceAll(',', '.')) ?? 0;
    if(limit == null) return false;
    if(_amount >= limit.min ){
       if(_provider is ChangeNowExchangeProvider && _amount >= limit.min){
         return true;
       } else if(_amount <= limit.max){
         return true;
       } 
    } 
    return false;
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
    isReceiveAmountEditable = provider is ChangeNowExchangeProvider;
  }
}
