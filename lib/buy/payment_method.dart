import 'dart:ui';

import 'package:cake_wallet/core/selectable_option.dart';

enum PaymentType {
  all,
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
  paypal,
  sepaOpenBankingPayment,
  gbpOpenBankingPayment,
  lowCostAch,
  mobileWallet,
  pixInstantPayment,
  yellowCardBankTransfer,
  fiatBalance,
  bancontact,
  unknown
}

extension PaymentTypeTitle on PaymentType {
  String? get title {
    switch (this) {
      case PaymentType.all:
        return 'All Payment Methods';
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
      case PaymentType.paypal:
        return 'PayPal';
      case PaymentType.sepaOpenBankingPayment:
        return 'SEPA Open Banking Payment';
      case PaymentType.gbpOpenBankingPayment:
        return 'GBP Open Banking Payment';
      case PaymentType.lowCostAch:
        return 'Low Cost ACH';
      case PaymentType.mobileWallet:
        return 'Mobile Wallet';
      case PaymentType.pixInstantPayment:
        return 'PIX Instant Payment';
      case PaymentType.yellowCardBankTransfer:
        return 'Yellow Card Bank Transfer';
      case PaymentType.fiatBalance:
        return 'Fiat Balance';
      case PaymentType.bancontact:
        return 'Bancontact';
      default:
        return null;
    }
  }

  String? get iconPath {
    switch (this) {
      case PaymentType.all:
        return 'assets/images/usd-circle.svg';
      case PaymentType.creditCard:
      case PaymentType.debitCard:
      case PaymentType.yellowCardBankTransfer:
        return 'assets/images/card.svg';
      case PaymentType.bankTransfer:
        return 'assets/images/bank.png';
      case PaymentType.skrill:
        return 'assets/images/skrill.svg';
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
  PaymentMethod({
    required this.paymentMethodType,
    required this.customTitle,
    required this.customIconPath,
    this.customDescription,
  }) : super(title: paymentMethodType.title ?? customTitle);

  final PaymentType paymentMethodType;
  final String customTitle;
  final String customIconPath;
  final String? customDescription;
  bool isSelected = false;

  @override
  String? get description => paymentMethodType.description ?? customDescription;

  @override
  String get iconPath => paymentMethodType.iconPath ?? customIconPath;

  @override
  bool get isOptionSelected => isSelected;

  factory PaymentMethod.all() {
    return PaymentMethod(
        paymentMethodType: PaymentType.all,
        customTitle: 'All Payment Methods',
        customIconPath: 'assets/images/dollar_coin.svg');
  }

  factory PaymentMethod.fromOnramperJson(Map<String, dynamic> json) {
    final type = PaymentMethod.getPaymentTypeId(json['paymentTypeId'] as String?);
    return PaymentMethod(
        paymentMethodType: type,
        customTitle: json['name'] as String? ?? 'Unknown',
        customIconPath: json['icon'] as String? ?? 'assets/images/card.png',
        customDescription: json['description'] as String?);
  }

  factory PaymentMethod.fromDFX(String paymentMethod, PaymentType paymentType) {
    return PaymentMethod(
        paymentMethodType: paymentType,
        customTitle: paymentMethod,
        customIconPath: 'assets/images/card.png');
  }

  factory PaymentMethod.fromMoonPayJson(Map<String, dynamic> json, PaymentType paymentType) {
    return PaymentMethod(
        paymentMethodType: paymentType,
        customTitle: json['paymentMethod'] as String,
        customIconPath: 'assets/images/card.png');
  }

  factory PaymentMethod.fromMeldJson(Map<String, dynamic> json) {
    final type = PaymentMethod.getPaymentTypeId(json['paymentMethod'] as String?);
    final logos = json['logos'] as Map<String, dynamic>;
    return PaymentMethod(
        paymentMethodType: type,
        customTitle: json['name'] as String? ?? 'Unknown',
        customIconPath: logos['dark'] as String? ?? 'assets/images/card.png',
        customDescription: json['description'] as String?);
  }

  static PaymentType getPaymentTypeId(String? type) {
    switch (type) {
      case 'banktransfer':
      case 'Bank':
      case 'yellow_card_bank_transfer':
        return PaymentType.bankTransfer;
      case 'creditcard':
      case 'Card':
      case 'CREDIT_DEBIT_CARD':
      case 'credit_debit_card':
        return PaymentType.creditCard;
      case 'debitcard':
        return PaymentType.debitCard;
      case 'applepay':
      case 'APPLE_PAY':
      case 'apple_pay':
        return PaymentType.applePay;
      case 'googlepay':
      case 'GOOGLE_PAY':
      case 'google_pay':
        return PaymentType.googlePay;
      case 'revolutpay':
        return PaymentType.revolutPay;
      case 'neteller':
      case 'NETELLER':
        return PaymentType.neteller;
      case 'skrill':
      case 'SKRILL':
        return PaymentType.skrill;
      case 'sepabanktransfer':
      case 'SEPA':
      case 'sepa_bank_transfer':
        return PaymentType.sepa;
      case 'sepainstant':
      case 'SEPA_INSTANT':
        return PaymentType.sepaInstant;
      case 'ACH':
      case 'ach_bank_transfer':
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
      case 'paypal':
        return PaymentType.paypal;
      case 'sepa_open_banking_payment':
        return PaymentType.sepaOpenBankingPayment;
      case 'bancontact':
        return PaymentType.bancontact;
      default:
        return PaymentType.unknown;
    }
  }
}
