import 'package:cake_wallet/buy/fiat_buy_credentials.dart';
import 'package:cake_wallet/core/selectable_option.dart';

enum PaymentType {
  bankTransfer,
  creditCard,
  debitCard,
  applePay,
  googlePay,
  revolutPay,
  neteller,
  skrill,
  sepa,
  sepaInstant,
  ach,
  achInstant,
  Khipu,
  palomaBanktTansfer,
  ovo,
  zaloPay,
  zaloBankTransfer,
  gcash,
  imps,
  dana,
  ideal,
  unknown
}


extension PaymentTypeTitle on PaymentType {
  String? get title {
    switch (this) {
      case PaymentType.bankTransfer:
        return 'Bank Transfer';
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
        case PaymentType.sepaInstant:
        return 'SEPA Instant';
      case PaymentType.ach:
        return 'ACH';
      case PaymentType.achInstant:
        return 'ACH Instant';
      case PaymentType.Khipu:
        return 'Khipu';
      case PaymentType.palomaBanktTansfer:
        return 'Paloma Bank Transfer';
      case PaymentType.ovo:
        return 'OVO';
      case PaymentType.zaloPay:
        return 'Zalo Pay';
      case PaymentType.zaloBankTransfer:
        return 'Zalo Bank Transfer';
      case PaymentType.gcash:
        return 'GCash';
      case PaymentType.imps:
        return 'IMPS';
      case PaymentType.dana:
        return 'DANA';
      case PaymentType.ideal:
        return 'iDEAL';
      default:
        return null;


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
      case PaymentType.sepa:
        return 'assets/images/card.png';
      case PaymentType.revolutPay:
        return 'assets/images/card.png';
      case PaymentType.googlePay:
        return 'assets/images/card.png';
      case PaymentType.applePay:
        return 'assets/images/card.png';
      case PaymentType.neteller:
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
  final PaymentType paymentMethodType;
  final String customTitle;
  final String customIconPath;
  final String customDescription;
  final VolumeLimits limits;
  bool isSelected = false;

  PaymentMethod({
    required this.paymentMethodType,
    required this.customTitle,
    required this.customIconPath,
    required this.customDescription,
    required this.limits,
  });

  @override
  String get title => paymentMethodType.title ?? customTitle;

  @override
  String get description => paymentMethodType.description ?? customDescription;

  @override
  String get iconPath => paymentMethodType.iconPath ?? customIconPath;

  @override
  bool get isOptionSelected => isSelected;

  factory PaymentMethod.fromOnramperJson(Map<String, dynamic> json) {
    final type = PaymentMethod.getPaymentTypeId(json['paymentTypeId'] as String?);
    return PaymentMethod(
      paymentMethodType: type,
      customTitle: json['name'] as String? ?? 'Unknown',
      customIconPath: json['icon'] as String? ?? 'assets/images/card.png',
      customDescription: json['description'] as String? ?? '',
      limits: VolumeLimits.fromJson(json['limits'] as Map<String, dynamic>? ?? {}),
    );
  }

  factory PaymentMethod.fromDFXJson(Map<String, dynamic> json, VolumeLimits limits) {
    final type = PaymentMethod.getPaymentTypeId(json['paymentTypeId'] as String?);
    print('PaymentMethod.fromDFXJson: type = $type');
    return PaymentMethod(
        paymentMethodType: type,
        customTitle: json['name'] as String? ?? 'Unknown',
        customIconPath: json['icon'] as String? ?? 'assets/images/card.png',
        customDescription: json['description'] as String? ?? '',
        limits: limits);
  }

  factory PaymentMethod.fromMeldJson(Map<String, dynamic> json) {
    final type = PaymentMethod.getPaymentTypeId(json['paymentMethod'] as String?);
    final logos = json['logos'] as Map<String, dynamic>;
    return PaymentMethod(
      paymentMethodType: type,
      customTitle: json['name'] as String? ?? 'Unknown',
      customIconPath: logos['dark'] as String? ?? 'assets/images/card.png',
      customDescription: json['description'] as String? ?? '',
      limits: VolumeLimits.fromJson(json['limits'] as Map<String, dynamic>? ?? {}),
    );
  }

  static PaymentType getPaymentTypeId(String? type) {
    switch (type) {
      case 'banktransfer':
      case 'Bank':
        return PaymentType.bankTransfer;
      case 'creditcard':
      case 'Card':
      case 'CREDIT_DEBIT_CARD"':
        return PaymentType.creditCard;
      case 'debitcard':
        return PaymentType.debitCard;
      case 'applepay':
      case 'APPLE_PAY':
        return PaymentType.applePay;
      case 'googlepay':
      case 'GOOGLE_PAY':
        return PaymentType.googlePay;
      case 'revolutpay':
        return PaymentType.revolutPay;
      case 'neteller':
      case 'ETELLER':
        return PaymentType.neteller;
      case 'skrill':
      case 'SKRILL':
        return PaymentType.skrill;
      case 'sepabanktransfer':
      case 'SEPA':
        return PaymentType.sepa;
      case 'sepainstant':
      case 'SEPA_INSTANT':
        return PaymentType.sepaInstant;
      case 'ACH':
        return PaymentType.ach;
      case 'iach':
      case 'INSTANT_ACH':
        return PaymentType.achInstant;
      case 'khipu':
      case 'KHIPU':
        return PaymentType.Khipu;
      case 'palomabanktransfer':
        return PaymentType.palomaBanktTansfer;
      case 'ovo':
      case 'OVO':
        return PaymentType.ovo;
      case 'zalopay':
      case 'ZALOPAY':
        return PaymentType.zaloPay;
      case 'zalobanktransfer':
      case 'ZA_BANK_TRANSFER':
        return PaymentType.zaloBankTransfer;
      case 'gcash':
      case 'GCASH':
        return PaymentType.gcash;
      case 'imps':
      case 'IMPS':
        return PaymentType.imps;
      case 'dana':
      case 'DANA':
        return PaymentType.dana;
      case 'ideal':
      case 'IDEAL':
        return PaymentType.ideal;
      default:
        return PaymentType.unknown;
    }
  }
}
