import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
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

part 'exchange_view_model.g.dart';

class ExchangeViewModel = ExchangeViewModelBase with _$ExchangeViewModel;

abstract class ExchangeViewModelBase with Store {
  ExchangeViewModelBase(
      this.wallet,
      this.trades,
      this._exchangeTemplateStore,
      this.tradesStore) {
    providerList = [
      XMRTOExchangeProvider(),
      ChangeNowExchangeProvider(),
      MorphTokenExchangeProvider(trades: trades)
    ];

    _initialPairBasedOnWallet();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
    depositAmount = '';
    receiveAmount = '';
    depositAddress = '';
    receiveAddress = '';
    limitsState = LimitsInitialState();
    tradeState = ExchangeTradeStateInitial();
    _cryptoNumberFormat = NumberFormat()..maximumFractionDigits = 12;
    provider = providersForCurrentPair().first;
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

  bool isReceiveAmountEntered;

  Limits limits;

  NumberFormat _cryptoNumberFormat;

  @computed
  ObservableList<ExchangeTemplate> get templates =>
      _exchangeTemplateStore.templates;

  @action
  void changeProvider({ExchangeProvider provider}) {
    this.provider = provider;
    depositAmount = '';
    receiveAmount = '';
    loadLimits();
  }

  @action
  void changeDepositCurrency({CryptoCurrency currency}) {
    depositCurrency = currency;
    _onPairChange();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
  }

  @action
  void changeReceiveCurrency({CryptoCurrency currency}) {
    receiveCurrency = currency;
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
            from: depositCurrency, to: receiveCurrency, amount: _amount,
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

    final _amount = double.parse(amount.replaceAll(',', '.'));
    provider
        .calculateAmount(
            from: depositCurrency, to: receiveCurrency, amount: _amount,
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
          from: depositCurrency, to: receiveCurrency);
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
          amount: depositAmount,
          receiveAmount: receiveAmount,
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
          amount: depositAmount,
          refundAddress: depositAddress,
          address: receiveAddress);
      amount = depositAmount;
      currency = depositCurrency;
    }

    if (provider is MorphTokenExchangeProvider) {
      request = MorphTokenRequest(
          from: depositCurrency,
          to: receiveCurrency,
          amount: depositAmount,
          refundAddress: depositAddress,
          address: receiveAddress);
      amount = depositAmount;
      currency = depositCurrency;
    }

    if (limitsState is LimitsLoadedSuccessfully && amount != null) {
      if (double.parse(amount) < limits.min) {
        tradeState = TradeIsCreatedFailure(
            error: S.current.error_text_minimal_limit('${provider.description}',
                '${limits.min}', currency.toString()));
      } else if (limits.max != null && double.parse(amount) > limits.max) {
        tradeState = TradeIsCreatedFailure(
            error: S.current.error_text_maximum_limit('${provider.description}',
                '${limits.max}', currency.toString()));
      } else {
        try {
          tradeState = TradeIsCreating();
          final trade = await provider.createTrade(request: request);
          trade.walletId = wallet.id;
          tradesStore.setTrade(trade);
          await trades.add(trade);
          tradeState = TradeIsCreatedSuccessfully(trade: trade);
        } catch (e) {
          tradeState = TradeIsCreatedFailure(error: e.toString());
        }
      }
    } else {
      tradeState = TradeIsCreatedFailure(
          error: S.current
              .error_text_limits_loading_failed('${provider.description}'));
    }
  }

  @action
  void reset() {
    depositAmount = '';
    receiveAmount = '';
    depositCurrency = CryptoCurrency.xmr;
    receiveCurrency = CryptoCurrency.btc;
    depositAddress = depositCurrency == wallet.currency ? wallet.address : '';
    receiveAddress = receiveCurrency == wallet.currency ? wallet.address : '';
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
    _onPairChange();
  }

  void updateTemplate() => _exchangeTemplateStore.update();

  void addTemplate({String amount, String depositCurrency, String receiveCurrency,
    String provider, String depositAddress, String receiveAddress}) =>
    _exchangeTemplateStore.addTemplate(
      amount: amount,
      depositCurrency: depositCurrency,
      receiveCurrency: receiveCurrency,
      provider: provider,
      depositAddress: depositAddress,
      receiveAddress: receiveAddress
    );

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

    if (!isPairExist) {
      final provider =
          _providerForPair(from: depositCurrency, to: receiveCurrency);

      if (provider != null) {
        changeProvider(provider: provider);
      }
    }

    depositAmount = '';
    receiveAmount = '';

    loadLimits();
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
}
