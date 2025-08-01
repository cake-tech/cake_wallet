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
  final String? minValueUsd;
  final String? maxValueUsd;
  final String? minValue;
  final String? maxValue;
  final List<Denomination> denominationItems;

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
    this.minValueUsd,
    this.maxValueUsd,
    this.minValue,
    this.maxValue,
    List<Denomination>? denominationItems,
  }) : denominationItems = denominationItems ?? const [];

  factory CakePayCard.fromJson(Map<String, dynamic> json) {
    final name = stripHtmlIfNeeded(json['name'] as String? ?? '');
    final description = stripHtmlIfNeeded(json['description'] as String? ?? '');
    final termsAndConditions = stripHtmlIfNeeded(json['terms_and_conditions'] as String? ?? '');
    final howToUse = stripHtmlIfNeeded(json['how_to_use'] as String? ?? '');
    final fiatCurrency = FiatCurrency.deserialize(raw: json['currency_code'] as String? ?? '');
    final parsedMinValue = _toDouble(json['min_value'] as String?);
    final minValue = fiatCurrency == FiatCurrency.usd && parsedMinValue != null && parsedMinValue < 10.00
        ? '10.00'
        : json['min_value'] as String?;
    final raw = (json['denominations'] as List?) ?? const [];
    final denominations = <Denomination>[];
    for (final item in raw) {
      if (item is Map) {
        denominations.add(Denomination.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return CakePayCard(
      id: json['id'] as int? ?? 0,
      name: name,
      description: description,
      termsAndConditions: termsAndConditions,
      howToUse: howToUse,
      expiryAndValidity: json['expiry_and_validity'] as String?,
      cardImageUrl: json['card_image_url'] as String?,
      country: json['country'] as String?,
      fiatCurrency: fiatCurrency,
      minValueUsd: json['min_value_usd'] as String?,
      maxValueUsd: json['max_value_usd'] as String?,
      minValue: minValue,
      maxValue: json['max_value'] as String?,
      denominationItems: denominations,
    );
  }

  List<Denomination> get denominationItemsWithUniqueValue {
    if (denominationItems.isEmpty) return const [];

    // unique by value and cardId
    final findExact = <String>{};
    final result = <Denomination>[];
    for (final item in denominationItems) {
      final str = '${item.value.toStringAsFixed(2)}|${item.cardId ?? 'null'}';
      if (findExact.add(str)) {
        result.add(item);
      }
    }

    final perValue = <String, Denomination>{};
    for (final item in result) {
      final valueKey = item.value.toStringAsFixed(2);
      final existing = perValue[valueKey];
      if (existing == null) {
        perValue[valueKey] = item;
      } else {
        final existingMatches = existing.cardId == id;
        final currentMatches = item.cardId == id;
        if (!existingMatches && currentMatches) {
          perValue[valueKey] = item;
        }
      }
    }

    final list = perValue.values.toList(growable: false)
      ..sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  static String stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class Denomination {
  final double value;
  final int? cardId;
  final double? usdValue;

  Denomination({
    required this.value,
    required this.cardId,
    this.usdValue,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory Denomination.fromJson(Map<String, dynamic> json) {
    return Denomination(
      value: _toDouble(json['value']) ?? 0,
      cardId: json['card_id'] is int ? json['card_id'] as int : int.tryParse('${json['card_id']}'),
      usdValue: _toDouble(json['usd_value']),
    );
  }
}
