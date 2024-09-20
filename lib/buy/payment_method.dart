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

  String? get lightIconPath {
    switch (this) {
      case PaymentType.all:
        return 'assets/images/usd_round_light.svg';
      case PaymentType.creditCard:
      case PaymentType.debitCard:
      case PaymentType.yellowCardBankTransfer:
        return 'assets/images/card.svg';
      case PaymentType.bankTransfer:
        return 'assets/images/bank_light.svg';
      case PaymentType.skrill:
        return 'assets/images/skrill.svg';
      case PaymentType.applePay:
        return 'assets/images/apple_pay_round_light.svg';
      default:
        return null;
    }
  }

  String? get darkIconPath {
    switch (this) {
      case PaymentType.all:
        return 'assets/images/usd_round_dark.svg';
      case PaymentType.creditCard:
      case PaymentType.debitCard:
      case PaymentType.yellowCardBankTransfer:
        return 'assets/images/card_dark.svg';
      case PaymentType.bankTransfer:
        return 'assets/images/bank_dark.svg';
      case PaymentType.skrill:
        return 'assets/images/skrill.svg';
      case PaymentType.applePay:
        return 'assets/images/apple_pay_round_dark.svg';
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
  String get lightIconPath => paymentMethodType.lightIconPath ?? customIconPath;

  @override
  String get darkIconPath => paymentMethodType.darkIconPath ?? customIconPath;

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
    switch (type?.toLowerCase()) {
      case 'banktransfer':
      case 'bank':
      case 'yellow_card_bank_transfer':
        return PaymentType.bankTransfer;
      case 'creditcard':
      case 'card':
      case 'credit_debit_card':
        return PaymentType.creditCard;
      case 'debitcard':
        return PaymentType.debitCard;
      case 'applepay':
      case 'apple_pay':
        return PaymentType.applePay;
      case 'googlepay':
      case 'google_pay':
        return PaymentType.googlePay;
      case 'revolutpay':
        return PaymentType.revolutPay;
      case 'neteller':
        return PaymentType.neteller;
      case 'skrill':
        return PaymentType.skrill;
      case 'sepabanktransfer':
      case 'sepa':
      case 'sepa_bank_transfer':
        return PaymentType.sepa;
      case 'sepainstant':
      case 'sepa_instant':
        return PaymentType.sepaInstant;
      case 'ach':
      case 'ach_bank_transfer':
        return PaymentType.ach;
      case 'iach':
      case 'instant_ach':
        return PaymentType.achInstant;
      case 'khipu':
        return PaymentType.Khipu;
      case 'palomabanktransfer':
        return PaymentType.palomaBanktTansfer;
      case 'ovo':
        return PaymentType.ovo;
      case 'zalopay':
        return PaymentType.zaloPay;
      case 'zalobanktransfer':
      case 'za_bank_transfer':
        return PaymentType.zaloBankTransfer;
      case 'gcash':
        return PaymentType.gcash;
      case 'imps':
        return PaymentType.imps;
      case 'dana':
        return PaymentType.dana;
      case 'ideal':
        return PaymentType.ideal;
      case 'paypal':
        return PaymentType.paypal;
      case 'sepa_open_banking_payment':
        return PaymentType.sepaOpenBankingPayment;
      case 'bancontact':
        return PaymentType.bancontact;
      default:
        return PaymentType.all;
    }
  }
}
