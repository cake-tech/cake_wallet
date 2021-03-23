import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/entities/find_order_by_id.dart';
import 'package:cake_wallet/entities/order.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';

class WyreViewModel {
  WyreViewModel(this.ordersSource, this.ordersStore,
      {@required this.walletId, @required this.address, @required this.type});

  final Box<Order> ordersSource;
  final OrdersStore ordersStore;

  final String walletId;
  final WalletType type;
  final String address;

  Future<void> saveOrder(String orderId) async {
    final order = await findOrderById(orderId);
    order.receiveAddress = address;
    order.walletId = walletId;
    await ordersSource.add(order);
    ordersStore.setOrder(order);
  }

  Future<String> getWyreUrl() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final url = 'https://api.sendwyre.com/v3/orders/reserve' +
        '?timestamp=' +
        timestamp;
    final secretKey = secrets.wyreSecretKey;
    final accountId = secrets.wyreAccountId;
    final body = {
      'destCurrency': walletTypeToCryptoCurrency(type).title,
      'dest': walletTypeToString(type).toLowerCase() + ':' + address,
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

    if (response.statusCode == 200) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final urlFromResponse = responseJSON['url'] as String;
      return urlFromResponse;
    } else {
      return '';
    }
  }
}
