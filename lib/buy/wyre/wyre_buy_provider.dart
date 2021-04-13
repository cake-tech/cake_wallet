import 'dart:convert';
import 'package:cake_wallet/buy/buy_exception.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class WyreBuyProvider extends BuyProvider {
  WyreBuyProvider({WalletBase wallet, bool isTestEnvironment = false})
    : super(wallet: wallet, isTestEnvironment: isTestEnvironment) {
    baseApiUrl = isTestEnvironment
        ? _baseTestApiUrl
        : _baseProductApiUrl;
  }

  static const _baseTestApiUrl = 'https://api.testwyre.com';
  static const _baseProductApiUrl = 'https://api.sendwyre.com';
  static const _trackTestUrl = 'https://dash.testwyre.com/track/';
  static const _trackProductUrl = 'https://dash.sendwyre.com/track/';
  static const _ordersSuffix = '/v3/orders';
  static const _reserveSuffix = '/reserve';
  static const _quoteSuffix = '/quote/partner';
  static const _timeStampSuffix = '?timestamp=';
  static const _transferSuffix = '/v2/transfer/';
  static const _trackSuffix = '/track';
  static const _secretKey = secrets.wyreSecretKey;
  static const _accountId = secrets.wyreAccountId;

  @override
  String get title => 'Wyre';

  @override
  BuyProviderDescription get description => BuyProviderDescription.wyre;

  @override
  String get trackUrl => isTestEnvironment
      ? _trackTestUrl
      : _trackProductUrl;

  String baseApiUrl;

  @override
  Future<String> requestUrl(String amount, String sourceCurrency) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final url = baseApiUrl + _ordersSuffix + _reserveSuffix +
        _timeStampSuffix + timestamp;
    final body = {
      'amount': amount,
      'sourceCurrency': sourceCurrency,
      'destCurrency': walletTypeToCryptoCurrency(walletType).title,
      'dest': walletTypeToString(walletType).toLowerCase() + ':' + walletAddress,
      'referrerAccountId': _accountId,
      'lockFields': ['amount', 'sourceCurrency', 'destCurrency', 'dest']
    };

    final response = await post(url,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
          'cache-control': 'no-cache'
        },
        body: json.encode(body));

    if (response.statusCode != 200) {
      throw BuyException(
          description: description,
          text: 'Url $url is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final urlFromResponse = responseJSON['url'] as String;
    return urlFromResponse;
  }

  @override
  Future<BuyAmount> calculateAmount(String amount, String sourceCurrency) async {
    final quoteUrl = baseApiUrl + _ordersSuffix + _quoteSuffix;
    final body = {
      'amount': amount,
      'sourceCurrency': sourceCurrency,
      'destCurrency': walletTypeToCryptoCurrency(walletType).title,
      'dest': walletTypeToString(walletType).toLowerCase() + ':' + walletAddress,
      'accountId': _accountId,
      'country': 'US' //FIXME
    };

    final response = await post(quoteUrl,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
          'cache-control': 'no-cache'
        },
        body: json.encode(body));

    if (response.statusCode != 200) {
      throw BuyException(
          description: description,
          text: 'Quote is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final sourceAmount = responseJSON['sourceAmount'] as double;
    final destAmount = responseJSON['destAmount'] as double;

    return BuyAmount(sourceAmount: sourceAmount, destAmount: destAmount);
  }

  @override
  Future<Order> findOrderById(String id) async {
    final orderUrl = baseApiUrl + _ordersSuffix + '/$id';
    final orderResponse = await get(orderUrl);

    if (orderResponse.statusCode != 200) {
      throw BuyException(
          description: description,
          text: 'Order $id is not found!');
    }

    final orderResponseJSON =
    json.decode(orderResponse.body) as Map<String, dynamic>;
    final transferId = orderResponseJSON['transferId'] as String;
    final from = orderResponseJSON['sourceCurrency'] as String;
    final to = orderResponseJSON['destCurrency'] as String;
    final status = orderResponseJSON['status'] as String;
    final state = TradeState.deserialize(raw: status.toLowerCase());
    final createdAtRaw = orderResponseJSON['createdAt'] as int;
    final createdAt =
    DateTime.fromMillisecondsSinceEpoch(createdAtRaw).toLocal();

    final transferUrl =
        baseApiUrl + _transferSuffix + transferId + _trackSuffix;
    final transferResponse = await get(transferUrl);

    if (transferResponse.statusCode != 200) {
      throw BuyException(
          description: description,
          text: 'Transfer $transferId is not found!');
    }

    final transferResponseJSON =
    json.decode(transferResponse.body) as Map<String, dynamic>;
    final amount = transferResponseJSON['destAmount'] as double;

    return Order(
        id: id,
        provider: description,
        transferId: transferId,
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