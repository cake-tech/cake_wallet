import 'dart:convert';
import 'package:cake_wallet/buy/buy_exception.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class MoonPayBuyProvider extends BuyProvider {
  MoonPayBuyProvider({WalletBase wallet, this.ordersSource,
      bool isTestEnvironment = false})
      : super(wallet: wallet, isTestEnvironment: isTestEnvironment) {
      baseApiUrl = isTestEnvironment
        ? _baseTestApiUrl
        : _baseProductApiUrl;
  }

  static const _baseTestApiUrl = 'https://buy-staging.moonpay.com';
  static const _baseProductApiUrl = 'https://api.moonpay.com';
  static const _currenciesSuffix = '/v3/currencies';
  static const _quoteSuffix = '/buy_quote';
  static const _transactionsSuffix = '/v1/transactions';
  static const _apiKey = secrets.moonPayApiKey;

  @override
  String get title => 'MoonPay';

  @override
  BuyProviderDescription get description => BuyProviderDescription.moonPay;

  String get currencyCode =>
    walletTypeToCryptoCurrency(walletType).title.toLowerCase();

  @override
  String get trackUrl => baseApiUrl + '/transaction_receipt?transactionId=';

  final Box<Order> ordersSource;
  String baseApiUrl;

  @override
  Future<String> requestUrl(String amount, String sourceCurrency) async {
    final enabledPaymentMethods =
        'credit_debit_card%2Capple_pay%2Cgoogle_pay%2Csamsung_pay'
        '%2Csepa_bank_transfer%2Cgbp_bank_transfer%2Cgbp_open_banking_payment';

    final originalUrl = baseApiUrl + '?apiKey=' + _apiKey + '&currencyCode=' +
        currencyCode + '&enabledPaymentMethods=' + enabledPaymentMethods +
        '&walletAddress=' + walletAddress +
        '&baseCurrencyCode=' + sourceCurrency.toLowerCase() +
        '&baseCurrencyAmount=' + amount + '&lockAmount=true' +
        '&showAllCurrencies=false' + '&showWalletAddressForm=false';

    return originalUrl;
  }

  @override
  Future<BuyAmount> calculateAmount(String amount, String sourceCurrency) async {
    final url = _baseProductApiUrl + _currenciesSuffix + '/$currencyCode' +
        _quoteSuffix + '/?apiKey=' + _apiKey +
        '&baseCurrencyAmount=' + amount +
        '&baseCurrencyCode' + sourceCurrency.toLowerCase();

    final response = await get(url);

    if (response.statusCode != 200) {
      throw BuyException(
          description: description,
          text: 'Quote is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final sourceAmount = responseJSON['totalAmount'] as double;
    final destAmount = responseJSON['quoteCurrencyAmount'] as double;

    return BuyAmount(sourceAmount: sourceAmount, destAmount: destAmount);
  }

  @override
  Future<Order> findOrderById(String id) async {
    final url = _baseProductApiUrl + _transactionsSuffix + '/$id' +
        '?apiKey=' + _apiKey;

    final response = await get(url);

    if (response.statusCode != 200) {
      throw BuyException(
          description: description,
          text: 'Transaction $id is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: status);
    final createdAtRaw = responseJSON['createdAt'] as String;
    final createdAt = DateTime.parse(createdAtRaw).toLocal();
    final amount = responseJSON['quoteCurrencyAmount'] as double;

    var from = '';
    var to = '';

    for (final order in ordersSource.values) {
      if (order.id == id) {
        from = order.from;
        to = order.to;
        break;
      }
    }

    return Order(
        id: id,
        provider: description,
        transferId: id,
        from: from,
        to: to,
        state: state,
        createdAt: createdAt,
        amount: amount.toString(),
        receiveAddress: walletAddress,
        walletId: walletId
    );
  }
}