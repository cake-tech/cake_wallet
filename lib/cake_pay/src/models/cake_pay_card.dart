import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';

enum CakePayCardType {
  prepaid('Prepaid Cards'),
  gift('gift'),
  onDemand('on_demand'),
  custom('custom');

  const CakePayCardType(this.apiValue);

  final String apiValue;
}

class CakePayCard {
  final int id;
  final String name;
  final CakePayCardType? type;
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
  final List<PrepaidRange> prepaidRange;

  CakePayCard(
      {required this.id,
      required this.name,
      this.type,
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
      List<PrepaidRange>? prepaidRange})
      : denominationItems = denominationItems ?? const [],
        prepaidRange = prepaidRange ?? const [];

  CakePayCard copyWith({
    int? id,
    String? name,
    CakePayCardType? type,
    String? description,
    String? termsAndConditions,
    String? howToUse,
    String? expiryAndValidity,
    String? cardImageUrl,
    String? country,
    FiatCurrency? fiatCurrency,
    String? minValueUsd,
    String? maxValueUsd,
    String? minValue,
    String? maxValue,
    List<Denomination>? denominationItems,
    List<PrepaidRange>? prepaidRange,
  }) {
    return CakePayCard(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      howToUse: howToUse ?? this.howToUse,
      expiryAndValidity: expiryAndValidity ?? this.expiryAndValidity,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      country: country ?? this.country,
      fiatCurrency: fiatCurrency ?? this.fiatCurrency,
      minValueUsd: minValueUsd ?? this.minValueUsd,
      maxValueUsd: maxValueUsd ?? this.maxValueUsd,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      denominationItems: denominationItems ?? this.denominationItems,
      prepaidRange: prepaidRange ?? this.prepaidRange,
    );
  }

  static CakePayCardType? cakePayCardTypeFromApi(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    return CakePayCardType.values.firstWhereOrNull(
      (e) => e.apiValue.toLowerCase() == normalized,
    );
  }

  factory CakePayCard.fromJson(Map<String, dynamic> json) {
    final name = stripHtmlIfNeeded(json['name'] as String? ?? '');
    final typeString = json['type'] as String? ?? '';
    final description = stripHtmlIfNeeded(json['description'] as String? ?? '');
    final termsAndConditions = stripHtmlIfNeeded(json['terms_and_conditions'] as String? ?? '');
    final howToUse = stripHtmlIfNeeded(json['how_to_use'] as String? ?? '');
    final fiatCurrency = FiatCurrency.deserialize(raw: json['currency_code'] as String? ?? '');

    String? minValue = json['min_value'] as String?;

    final parsedMinValueLocal = _toDouble(json['min_value']);
    final parsedMinValueUsd = _toDouble(json['min_value_usd']);

    if (parsedMinValueLocal != null &&
        parsedMinValueLocal > 0 &&
        parsedMinValueUsd != null &&
        parsedMinValueUsd > 0 &&
        parsedMinValueUsd < 10.0) {
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

    final cakePayCardType = cakePayCardTypeFromApi(typeString);

    return CakePayCard(
      id: json['id'] as int? ?? 0,
      name: name,
      type: cakePayCardType,
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

  factory Denomination.fromJson(Map<String, dynamic> json) {
    return Denomination(
      value: _toDouble(json['value']) ?? 0,
      cardId: json['card_id'] is int ? json['card_id'] as int : int.tryParse('${json['card_id']}'),
      usdValue: _toDouble(json['usd_value']),
    );
  }
}

class PrepaidRange {
  final double minValue;
  final double maxValue;
  final String rangeId;

  PrepaidRange({
    required this.minValue,
    required this.maxValue,
    required this.rangeId,
  });

  factory PrepaidRange.fromCard(CakePayCard card) {
    return PrepaidRange(
      minValue: _toDouble(card.minValue) ?? 0,
      maxValue: _toDouble(card.maxValue) ?? 0,
      rangeId: card.id.toString(),
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
