import 'package:cake_wallet/core/selectable_option.dart';

enum PaymentMethodType {
  creditCard,
  debitCard,
  applePay,
  googlePay,
  revolutPay,
  neteller,
  skrill,
  sepa
}

class PaymentMethod extends SelectableOption {
  final PaymentMethodType? paymentMethodType;
  final String title;
  final String icon;
  final Map<String, dynamic> details;
  bool isSelected = false;

  PaymentMethod({
    this.paymentMethodType,
    required this.title,
    required this.icon,
    required this.details,
  });

  @override
  bool get isOptionSelected => isSelected;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final type = PaymentMethod.getPaymentTypeId(json['paymentTypeId'] as String?);
    final iconPath = PaymentMethod.getIconPath(type);

    return PaymentMethod(
      paymentMethodType: type,
      title: json['name'] as String,
      icon: iconPath,
      details: json['details'] as Map<String, dynamic>,
    );
  }

  static PaymentMethodType? getPaymentTypeId(String? type) {
    switch (type) {
      case 'creditcard':
        return PaymentMethodType.creditCard;
      case 'debitcard':
        return PaymentMethodType.debitCard;
      case 'applepay':
        return PaymentMethodType.applePay;
      case 'googlepay':
        return PaymentMethodType.googlePay;
      case 'revolutpay':
        return PaymentMethodType.revolutPay;
      case 'neteller':
        return PaymentMethodType.neteller;
      case 'skrill':
        return PaymentMethodType.skrill;
      default:
        throw Exception('Unknown payment type');
    }
  }

  static String getIconPath(PaymentMethodType? type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'assets/images/card.png';
      case PaymentMethodType.debitCard:
        return 'assets/images/card.png';
      case PaymentMethodType.applePay:
        return 'assets/images/apple_pay_logo.png';
      case PaymentMethodType.googlePay:
        return 'assets/images/google_pay_icon.png';
      case PaymentMethodType.revolutPay:
        return 'assets/images/revolut.png';
      default:
        return 'assets/images/card.png';
    }
  }

  @override
  String get description => '';

  @override
  String get iconPath => icon;
}
