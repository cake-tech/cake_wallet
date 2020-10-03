import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/changenow/changenow_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/changenow/changenow_request.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/morphtoken/morphtoken_request.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/src/stores/exchange/limits_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/exchange/limits.dart';
import 'package:intl/intl.dart';

part 'exchange_store.g.dart';

class ExchangeStore = ExchangeStoreBase with _$ExchangeStore;

abstract class ExchangeStoreBase with Store {
  ExchangeStoreBase(
      {@required ExchangeProvider initialProvider,
      @required CryptoCurrency initialDepositCurrency,
      @required CryptoCurrency initialReceiveCurrency,
      @required this.providerList,
      @required this.trades,
      @required this.walletStore}) {
    provider = initialProvider;
    depositCurrency = initialDepositCurrency;
    receiveCurrency = initialReceiveCurrency;
    limitsState = LimitsInitialState();
    tradeState = ExchangeTradeStateInitial();
    _cryptoNumberFormat = NumberFormat()..maximumFractionDigits = 12;
    loadLimits();
  }

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
  bool isValid;

  @observable
  String errorMessage;

  Box<Trade> trades;

  String depositAddress;

  String receiveAddress;

  WalletStore walletStore;

  Limits limits;

  NumberFormat _cryptoNumberFormat;

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
  }

  @action
  void changeReceiveCurrency({CryptoCurrency currency}) {
    receiveCurrency = currency;
    _onPairChange();
  }

  @action
  void changeReceiveAmount({String amount}) {
    receiveAmount = amount;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _amount = double.parse(amount) ?? 0;

    provider
        .calculateAmount(
            from: depositCurrency, to: receiveCurrency, amount: _amount)
        .then((amount) => _cryptoNumberFormat.format(amount).toString().replaceAll(RegExp("\\,"), ""))
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

    final _amount = double.parse(amount);
    provider
        .calculateAmount(
            from: depositCurrency, to: receiveCurrency, amount: _amount)
        .then((amount) => _cryptoNumberFormat.format(amount).toString().replaceAll(RegExp("\\,"), ""))
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
          address: receiveAddress,
          refundAddress: depositAddress);
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
        tradeState = TradeIsCreatedFailure(error: S.current.error_text_minimal_limit("${provider.description}",
            "${limits.min}", currency.toString()));
      } else if (limits.max != null && double.parse(amount) > limits.max) {
        tradeState = TradeIsCreatedFailure(error: S.current.error_text_maximum_limit("${provider.description}",
            "${limits.max}", currency.toString()));
      } else {
        try {
          tradeState = TradeIsCreating();
          final trade = await provider.createTrade(request: request);
          trade.walletId = walletStore.id;
          await trades.add(trade);
          tradeState = TradeIsCreatedSuccessfully(trade: trade);
        } catch (e) {
          tradeState = TradeIsCreatedFailure(error: e.toString());
        }
      }
    } else {
      tradeState = TradeIsCreatedFailure(error: S.current.error_text_limits_loading_failed("${provider.description}"));
    }

  }

  @action
  void reset() {
    depositAmount = '';
    receiveAmount = '';
    depositAddress = '';
    receiveAddress = '';
    provider = XMRTOExchangeProvider();
    depositCurrency = CryptoCurrency.xmr;
    receiveCurrency = CryptoCurrency.btc;
    loadLimits();
  }

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

  void validateAddress(String value, {CryptoCurrency cryptoCurrency}) {
    // XMR (95, 106), ADA (59, 92, 105), BCH (42), BNB (42), BTC (34, 42), DASH (34), EOS (42),
    // ETH (42), LTC (34), NANO (64, 65), TRX (34), USDT (42), XLM (56), XRP (34)
    const pattern = '^[0-9a-zA-Z]{95}\$|^[0-9a-zA-Z]{34}\$|^[0-9a-zA-Z]{42}\$|^[0-9a-zA-Z]{56}\$|^[0-9a-zA-Z]{59}\$|^[0-9a-zA-Z_]{64}\$|^[0-9a-zA-Z_]{65}\$|^[0-9a-zA-Z]{92}\$|^[0-9a-zA-Z]{105}\$|^[0-9a-zA-Z]{106}\$';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);
    if (isValid && cryptoCurrency != null) {
      switch (cryptoCurrency) {
        case CryptoCurrency.xmr:
          isValid = (value.length == 95)||(value.length == 106);
          break;
        case CryptoCurrency.ada:
          isValid = (value.length == 59)||(value.length == 92)||(value.length == 105);
          break;
        case CryptoCurrency.bch:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.bnb:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.btc:
          isValid = (value.length == 34)||(value.length == 42)||(value.length == 62);
          break;
        case CryptoCurrency.dash:
          isValid = (value.length == 34);
          break;
        case CryptoCurrency.eos:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.eth:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.ltc:
          isValid = (value.length == 34);
          break;
        case CryptoCurrency.nano:
          isValid = (value.length == 64)||(value.length == 65);
          break;
        case CryptoCurrency.trx:
          isValid = (value.length == 34);
          break;
        case CryptoCurrency.usdt:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.xlm:
          isValid = (value.length == 56);
          break;
        case CryptoCurrency.xrp:
          isValid = (value.length == 34);
          break;
      }
    }

    errorMessage = isValid ? null : S.current.error_text_address;
  }

  void validateCryptoCurrency(String value) {
    const pattern = '^([0-9]+([.][0-9]{0,12})?|[.][0-9]{1,12})\$';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);
    errorMessage = isValid ? null : S.current.error_text_crypto_currency;
  }
}
