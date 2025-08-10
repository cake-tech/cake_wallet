import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/order/order.dart';

abstract class OrderProvider {
  Future<Order> findOrderById(String id, {CakePayPaymentMethod? paymentMethod});

  String get title;

  String get trackUrl;
}
