import 'dart:convert';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/ionia/ionia_gift_card_instruction.dart';
import 'package:flutter/foundation.dart';

class IoniaGiftCard {
  IoniaGiftCard(
      {required this.id,
      required this.merchantId,
      required this.legalName,
      required this.systemName,
      required this.barcodeUrl,
      required this.cardNumber,
      required this.cardPin,
      required this.instructions,
      required this.tip,
      required this.purchaseAmount,
      required this.actualAmount,
      required this.totalTransactionAmount,
      required this.totalDashTransactionAmount,
      required this.remainingAmount,
      required this.createdDateFormatted,
      required this.lastTransactionDateFormatted,
      required this.isActive,
      required this.isEmpty,
      required this.logoUrl});

  factory IoniaGiftCard.fromJsonMap(Map<String, dynamic> element) {
    return IoniaGiftCard(
        id: element['Id'] as int,
        merchantId: element['MerchantId'] as int,
        legalName: element['LegalName'] as String,
        systemName: element['SystemName'] as String,
        barcodeUrl: element['BarcodeUrl'] as String,
        cardNumber: element['CardNumber'] as String,
        cardPin: element['CardPin'] as String,
        tip: element['Tip'] as double,
        purchaseAmount: element['PurchaseAmount'] as double,
        actualAmount: element['ActualAmount'] as double,
        totalTransactionAmount: element['TotalTransactionAmount'] as double,
        totalDashTransactionAmount: (element['TotalDashTransactionAmount'] as double?) ?? 0.0,
        remainingAmount: element['RemainingAmount'] as double,
        isActive: element['IsActive'] as bool,
        isEmpty: element['IsEmpty'] as bool,
        logoUrl: element['LogoUrl'] as String,
        createdDateFormatted: element['CreatedDate'] as String,
        lastTransactionDateFormatted: element['LastTransactionDate'] as String,
        instructions: IoniaGiftCardInstruction.parseListOfInstructions(
            element['PaymentInstructions'] as String));
  }

  final int id;
  final int merchantId;
  final String legalName;
  final String systemName;
  final String barcodeUrl;
  final String cardNumber;
  final String cardPin;
  final List<IoniaGiftCardInstruction> instructions;
  final double tip;
  final double purchaseAmount;
  final double actualAmount;
  final double totalTransactionAmount;
  final double totalDashTransactionAmount;
  double remainingAmount;
  final String createdDateFormatted;
  final String lastTransactionDateFormatted;
  final bool isActive;
  final bool isEmpty;
  final String logoUrl;
}

class CakePayCard {
  final int id;
  final String name;
  final String? description;
  final String? termsAndConditions;
  final String? howToUse;
  final String? expiryAndValidity;
  final String? cardImageUrl;
  final String? country;
  final FiatCurrency fiatCurrency;
  final List<String> denominationsUsd;
  final List<String> denominations;
  final String? minValueUsd;
  final String? maxValueUsd;
  final String? minValue;
  final String? maxValue;

  CakePayCard({
    required this.id,
    required this.name,
    this.description,
    this.termsAndConditions,
    this.howToUse,
    this.expiryAndValidity,
    this.cardImageUrl,
    this.country,
    required this.fiatCurrency,
    required this.denominationsUsd,
    required this.denominations,
    this.minValueUsd,
    this.maxValueUsd,
    this.minValue,
    this.maxValue,
  });

  factory CakePayCard.fromJson(Map<String, dynamic> json) {
    final name = stripHtmlIfNeeded(json['name'] as String? ?? '');
    final decodedName = fixEncoding(name);

    final description = stripHtmlIfNeeded(json['description'] as String? ?? '');
    final decodedDescription = fixEncoding(description);

    final termsAndConditions = stripHtmlIfNeeded(json['terms_and_conditions'] as String? ?? '');
    final decodedTermsAndConditions = fixEncoding(termsAndConditions);

    final howToUse = stripHtmlIfNeeded(json['how_to_use'] as String? ?? '');
    final decodedHowToUse = fixEncoding(howToUse);

    final fiatCurrency = FiatCurrency.deserialize(raw: json['currency_code'] as String? ?? '');

    final List<String> denominationsUsd = (json['denominations_usd'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final List<String> denominations = (json['denominations'] as List?)?.map((e) => e.toString()).toList() ?? [];


    return CakePayCard(
      id: json['id'] as int? ?? 0,
      name: decodedName,
      description: decodedDescription,
      termsAndConditions: decodedTermsAndConditions,
      howToUse: decodedHowToUse,
      expiryAndValidity: json['expiry_and_validity'] as String?,
      cardImageUrl: json['card_image_url'] as String?,
      country: json['country'] as String?,
      fiatCurrency: fiatCurrency,
      denominationsUsd: denominationsUsd,
      denominations: denominations,
      minValueUsd: json['min_value_usd'] as String?,
      maxValueUsd: json['max_value_usd'] as String?,
      minValue: json['min_value'] as String?,
      maxValue: json['max_value'] as String?,
    );
  }

  static String stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }

  static String fixEncoding(String text) {
    final bytes = latin1.encode(text);
    return utf8.decode(bytes, allowMalformed: true);
  }
}
