import 'dart:convert';

import 'package:cake_wallet/entities/fiat_currency.dart';

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

    final List<String> denominationsUsd =
        (json['denominations_usd'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final List<String> denominations =
        (json['denominations'] as List?)?.map((e) => e.toString()).toList() ?? [];

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
    try {
      final bytes = latin1.encode(text);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return text;
    }
  }
}
