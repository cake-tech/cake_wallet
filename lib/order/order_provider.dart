import 'package:cake_wallet/order/order.dart';

abstract class OrderProvider {
  Future<(Order, Object?)> findOrderById(String id);

  String get title;

  String get trackUrl;
}
