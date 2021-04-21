import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_priority.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
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
import 'package:cake_wallet/exchange/sideshift/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/sideshift/sideshift_request.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_trade_request.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_request.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';

part 'exchange_view_model.g.dart';

class ExchangeViewModel = ExchangeViewModelBase with _$ExchangeViewModel;

abstract class ExchangeViewModelBase with Store {
  ExchangeViewModelBase(this.wallet, this.trades, this._exchangeTemplateStore,
      this.tradesStore, this._settingsStore) {
    providerList = [
      SideShiftExchangeProvider(),
      ChangeNowExchangeProvider(),
    ];

    _initialPairBasedOnWallet();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
    depositAmount = '';
    receiveAmount = '';
    receiveAddress = '';
    depositAddress = depositCurrency == wallet.currency ? wallet.address : '';
    limitsState = LimitsInitialState();
    tradeState = ExchangeTradeStateInitial();
    _cryptoNumberFormat = NumberFormat()..maximumFractionDigits = 12;
    provider = providersForCurrentPair().first;
    final initialProvider = provider;
    provider.checkIsAvailable().then((bool isAvailable) {
      if (!isAvailable && provider == initialProvider) {
        provider = providerList.firstWhere(
            (provider) => provider is ChangeNowExchangeProvider,
            orElse: () => providerList.last);
        _onPairChange();
      }
    });
    receiveCurrencies = CryptoCurrency.all
            .where((cryptoCurrency) =>
                (cryptoCurrency != CryptoCurrency.xlm) &&
                (cryptoCurrency != CryptoCurrency.xrp))
            .toList();
    _defineIsReceiveAmountEditable();
    isFixedRateMode = provider is SideShiftExchangeProvider ? true : false;
    isReceiveAmountEntered = false;
    loadLimits();
  }

  final WalletBase wallet;
  final Box<Trade> trades;
  final ExchangeTemplateStore _exchangeTemplateStore;
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

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  ObservableList<ExchangeTemplate> get templates =>
      _exchangeTemplateStore.templates;

  bool get hasAllAmount =>
      wallet.type == WalletType.bitcoin && depositCurrency == wallet.currency;

  List<CryptoCurrency> receiveCurrencies;

  Limits limits;

  NumberFormat _cryptoNumberFormat;

  SettingsStore _settingsStore;

  @action
  void changeProvider({ExchangeProvider provider}) {
    this.provider = provider;
    depositAmount = '';
    receiveAmount = '';
    isFixedRateMode = provider is SideShiftExchangeProvider ? true : false;
    _defineIsReceiveAmountEditable();
    loadLimits();
  }

  @action
  void changeDepositCurrency({CryptoCurrency currency}) {
    depositCurrency = currency;
    isFixedRateMode = provider is SideShiftExchangeProvider ? true : false;
    _onPairChange();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
  }

  @action
  void changeReceiveCurrency({CryptoCurrency currency}) {
    receiveCurrency = currency;
    isFixedRateMode = provider is SideShiftExchangeProvider ? true : false;
    _onPairChange();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
  }

  @action
  void changeReceiveAmount({String amount}) {
    receiveAmount = amount;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _amount = double.parse(amount.replaceAll(',', '.')) ?? 0;

    provider
        .calculateAmount(
            from: receiveCurrency,
            to: depositCurrency,
            amount: _amount,
            isFixedRateMode: isFixedRateMode,
            isReceiveAmount: true)
        .then((amount) => _cryptoNumberFormat
            .format(amount)
            .toString()
            .replaceAll(RegExp('\\,'), ''))
        .then((amount) => depositAmount = amount);
  }

  @action
  void changeDepositAmount({String amount}) {
    depositAmount = amount;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _amount = double.parse(amount.replaceAll(',', '.')) ?? 0;
    provider
        .calculateAmount(
            from: depositCurrency,
            to: receiveCurrency,
            amount: _amount,
            isFixedRateMode: isFixedRateMode,
            isReceiveAmount: false)
        .then((amount) => _cryptoNumberFormat
            .format(amount)
            .toString()
            .replaceAll(RegExp('\\,'), ''))
        .then((amount) => receiveAmount = amount);
  }

  @action
  Future loadLimits() async {
    limitsState = LimitsIsLoading();

    try {
      limits = await provider.fetchLimits(
          from: depositCurrency,
          to: receiveCurrency,
          isFixedRateMode: isFixedRateMode);
      limitsState = LimitsLoadedSuccessfully(limits: limits);
    } catch (e) {
      limitsState = LimitsLoadedFailure(error: e.toString());
    }
  }

  @action
  Future createTrade() async {
    TradeRequest request;
    String amount;
    CryptoCurrency currency;

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
          amount: depositAmount?.replaceAll(',', '.'),
          refundAddress: depositAddress,
          address: receiveAddress);
      amount = depositAmount;
      currency = depositCurrency;
    }

    if (provider is SideShiftExchangeProvider) {
      request = SideShiftRequest(
          depositMethod: depositCurrency,
          settleMethod: receiveCurrency,
          depositAmount: depositAmount?.replaceAll(',', '.'),
          refundAddress: depositAddress,
          settleAddress: receiveAddress);
      amount = depositAmount;
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
    depositAddress = depositCurrency == wallet.currency ? wallet.address : '';
    receiveAddress = receiveCurrency == wallet.currency ? wallet.address : '';
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
    isFixedRateMode = false;
    _onPairChange();
  }

  @action
  void calculateDepositAllAmount() {
    if (wallet is BitcoinWallet) {
      final availableBalance = wallet.balance.available;
      final priority =
          _settingsStore.priority[wallet.type] as BitcoinTransactionPriority;
      final fee = wallet.calculateEstimatedFee(priority, null);

      if (availableBalance < fee || availableBalance == 0) {
        return;
      }

      final amount = availableBalance - fee;
      changeDepositAmount(amount: bitcoinAmountToString(amount: amount));
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

  List<ExchangeProvider> providersForCurrentPair() {
    return _providersForPair(from: depositCurrency, to: receiveCurrency);
  }

  List<ExchangeProvider> _providersForPair(
      {CryptoCurrency from, CryptoCurrency to}) {
    final providers = providerList
        .where((provider) => provider.pairList
            .where((pair) =>
                pair.from == depositCurrency && pair.to == receiveCurrency)
            .isNotEmpty)
        .toList();

    return providers;
  }

  void _onPairChange() {
    final isPairExist = provider.pairList
        .where((pair) =>
            pair.from == depositCurrency && pair.to == receiveCurrency)
        .isNotEmpty;

    if (isPairExist) {
      final provider =
          _providerForPair(from: depositCurrency, to: receiveCurrency);

      if (provider != null) {
        changeProvider(provider: provider);
      }
    } else {
      depositAmount = '';
      receiveAmount = '';
    }
  }

  ExchangeProvider _providerForPair({CryptoCurrency from, CryptoCurrency to}) {
    final providers = _providersForPair(from: from, to: to);
    return providers.isNotEmpty ? providers[0] : null;
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
    isReceiveAmountEditable = false;
  }
}
