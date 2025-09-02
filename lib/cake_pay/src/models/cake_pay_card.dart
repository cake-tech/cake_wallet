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

    String? minValue = json['min_value'] as String?;

    final parsedMinValueLocal = _toDouble(json['min_value']);
    final parsedMinValueUsd = _toDouble(json['min_value_usd']);

    if (parsedMinValueLocal != null && parsedMinValueLocal > 0 && parsedMinValueUsd != null && parsedMinValueUsd > 0 && parsedMinValueUsd < 10.0) {
      final rate = parsedMinValueLocal / parsedMinValueUsd;
      final minLocalValueLimit = 10.0 * rate;
      minValue = minLocalValueLimit.toStringAsFixed(2);
    }

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
