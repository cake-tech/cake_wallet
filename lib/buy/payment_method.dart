import 'package:cake_wallet/core/selectable_option.dart';

enum PaymentType {
  creditCard,
  debitCard,
  applePay,
  googlePay,
  revolutPay,
  neteller,
  skrill,
  sepa
}

extension PaymentTypeTitle on PaymentType {
  String get title {
    switch (this) {
      case PaymentType.creditCard:
        return 'Credit Card';
      case PaymentType.debitCard:
        return 'Debit Card';
      case PaymentType.applePay:
        return 'Apple Pay';
      case PaymentType.googlePay:
        return 'Google Pay';
      case PaymentType.revolutPay:
        return 'Revolut Pay';
      case PaymentType.neteller:
        return 'Neteller';
      case PaymentType.skrill:
        return 'Skrill';
      case PaymentType.sepa:
        return 'SEPA';
      default:
        return 'Unknown';
    }
  }

  String? get iconPath {
    switch (this) {
      case PaymentType.creditCard:
      case PaymentType.debitCard:
        return 'assets/images/card.png';
      case PaymentType.debitCard:
        return 'assets/images/card.png';
      case PaymentType.skrill:
        return 'assets/images/card.png';
      default:
        return null;
    }
  }

  String? get description {
    switch (this) {
      default:
        return null;
    }
  }
}

class PaymentMethod extends SelectableOption {
  final PaymentType? paymentMethodType;
  final String customTitle;
  final String customIconPath;
  final String customDescription;
  bool isSelected = false;

  PaymentMethod({
    this.paymentMethodType,
    required this.customTitle,
    required this.customIconPath,
    required this.customDescription,
  });

  @override
  String get title =>
      paymentMethodType?.title ?? customTitle;

  @override
  String get description =>
      paymentMethodType?.description ?? customDescription;

  @override
  String get iconPath =>
      paymentMethodType?.iconPath ?? customIconPath;

  @override
  bool get isOptionSelected => isSelected;

  factory PaymentMethod.fromOnramperJson(Map<String, dynamic> json) {
    final type = PaymentMethod.getPaymentTypeId(json['paymentTypeId'] as String?);
    return PaymentMethod(
      paymentMethodType: type,
      customTitle: json['name'] as String? ?? 'Unknown',
      customIconPath: json['icon'] as String? ?? 'assets/images/default.png',
      customDescription: json['description'] as String? ?? '',
    );
  }

  factory PaymentMethod.fromMeldJson(Map<String, dynamic> json) {
    final type = PaymentMethod.getPaymentTypeId(json['paymentMethod'] as String?);
    final logos = json['logos'] as Map<String, dynamic>;
    return PaymentMethod(
      paymentMethodType: type,
      customTitle: json['name'] as String? ?? 'Unknown',
      customIconPath: logos['dark'] as String? ?? 'assets/images/default.png',
      customDescription: json['description'] as String? ?? '',
    );
  }

  static PaymentType? getPaymentTypeId(String? type) {
    switch (type) {
      case 'creditcard':
        return PaymentType.creditCard;
      case 'debitcard':
        return PaymentType.debitCard;
      case 'applepay':
        return PaymentType.applePay;
      case 'googlepay':
        return PaymentType.googlePay;
      case 'revolutpay':
        return PaymentType.revolutPay;
      case 'neteller':
        return PaymentType.neteller;
      case 'skrill':
        return PaymentType.skrill;
      case 'sepa':
        return PaymentType.sepa;
      default:
        return null;
    }
  }
}