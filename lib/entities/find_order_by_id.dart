import 'dart:convert';
import 'package:cake_wallet/entities/order.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:http/http.dart';

Future<Order> findOrderById(String id) async {
  final orderUrl = 'https://api.sendwyre.com/v3/orders/' + id;

  final orderResponse = await get(orderUrl);

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
      'https://api.sendwyre.com/v2/transfer/' + transferId + '/track';

  final transferResponse = await get(transferUrl);

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