import 'dart:convert';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/entities/order.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

class WyreService {
  WyreService({
    @required this.walletType,
    @required this.walletAddress,
    this.isTestEnvironment = false}) {
    baseApiUrl = isTestEnvironment
        ? 'https://api.testwyre.com'
        : 'https://api.sendwyre.com';
    trackUrl = isTestEnvironment
        ? 'https://dash.testwyre.com/track/'
        : 'https://dash.sendwyre.com/track/';
  }

  static const _ordersSuffix = '/v3/orders';
  static const _reserveSuffix = '/reserve';
  static const _timeStampSuffix = '?timestamp=';
  static const _transferSuffix = '/v2/transfer/';
  static const _trackSuffix = '/track';

  final bool isTestEnvironment;
  final WalletType walletType;
  final String walletAddress;

  String baseApiUrl;
  String trackUrl;

  Future<String> getWyreUrl() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final url = baseApiUrl + _ordersSuffix + _reserveSuffix +
        _timeStampSuffix + timestamp;
    final secretKey = secrets.wyreSecretKey;
    final accountId = secrets.wyreAccountId;
    final body = {
      'destCurrency': walletTypeToCryptoCurrency(walletType).title,
      'dest': walletTypeToString(walletType).toLowerCase() + ':' + walletAddress,
      'referrerAccountId': accountId,
      'lockFields': ['destCurrency', 'dest']
    };

    final response = await post(url,
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/json',
          'cache-control': 'no-cache'
        },
        body: json.encode(body));

    if (response.statusCode != 200) {
      throw WyreException('Url $url is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final urlFromResponse = responseJSON['url'] as String;
    return urlFromResponse;
  }

  Future<Order> findOrderById(String id) async {
    final orderUrl = baseApiUrl + _ordersSuffix + id;
    final orderResponse = await get(orderUrl);

    if (orderResponse.statusCode != 200) {
      throw WyreException('Order $id is not found!');
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
      throw WyreException('Transfer $transferId is not found!');
    }

    final transferResponseJSON =
    json.decode(transferResponse.body) as Map<String, dynamic>;
    final amount = transferResponseJSON['destAmount'] as double;

    return Order(
        id: id,
        transferId: transferId,
        from: from,
        to: to,
        state: state,
        createdAt: createdAt,
        amount: amount.toString()
    );
  }
}

class WyreException implements Exception {
  WyreException(this.description);

  String description;

  @override
  String toString() => description;
}