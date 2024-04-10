import 'package:cake_wallet/anypay/any_pay_payment.dart';

class IoniaAnyPayPaymentInfo {
  const IoniaAnyPayPaymentInfo(this.ioniaOrder, this.anyPayPayment);

  final IoniaOrder ioniaOrder;
  final AnyPayPayment anyPayPayment;
}

class IoniaOrder {
  IoniaOrder(
      {required this.id,
      required this.uri,
      required this.currency,
      required this.amount,
      required this.paymentId});

  factory IoniaOrder.fromMap(Map<String, dynamic> obj) {
    return IoniaOrder(
        id: obj['order_id'] as String,
        uri: obj['uri'] as String,
        currency: obj['currency'] as String,
        amount: obj['amount'] as double,
        paymentId: obj['paymentId'] as String);
  }

  final String id;
  final String uri;
  final String currency;
  final double amount;
  final String paymentId;
}
