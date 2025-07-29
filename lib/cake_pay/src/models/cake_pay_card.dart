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

    List<Denomination> parsedDenomination = [];
    final rawDenomination = json['denominations'];

    if (rawDenomination is List) {
      if (rawDenomination.isNotEmpty && rawDenomination.first is Map) {
        parsedDenomination = rawDenomination
            .whereType<Map<dynamic, dynamic>>()
            .map<Denomination>((e) => Denomination.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        parsedDenomination = rawDenomination
            .map((e) => Denomination(value: Denomination._toDouble(e) ?? 0))
            .toList();
      }
    } else if (rawDenomination is Map) {
      final desc = rawDenomination['description'];
      if (desc is List) {
        parsedDenomination =
            desc.map((e) => Denomination(value: Denomination._toDouble(e) ?? 0)).toList();
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
      minValue: json['min_value'] as String?,
      maxValue: json['max_value'] as String?,
      denominationItems: parsedDenomination,
    );
  }

  List<Denomination> get denominationItemsUnique {
    if (denominationItems.isEmpty) return const [];
    final map = <String, Denomination>{};
    for (final d in denominationItems) {
      final key = d.value.toStringAsFixed(2);
      if (!map.containsKey(key)) {
        map[key] = d;
      } else {
        final current = map[key]!;
        if (current.cardId != id && d.cardId == id) {
          map[key] = d;
        }
      }
    }
    return map.values.toList();
  }

  bool get hasDenominations => denominationItemsUnique.isNotEmpty;

  List<String> get denominations =>
      denominationItemsUnique.map((e) => _fmtValue(e.value)).toList(growable: false);

  static String _fmtValue(double v) {
    final intPart = v.truncate();
    if (v == intPart) return intPart.toString();
    var s = v.toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  static String stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }
}

class Denomination {
  final double value;
  final int? cardId;
  final double? usdValue;

  Denomination({
    required this.value,
    this.cardId,
    this.usdValue,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory Denomination.fromJson(Map<String, dynamic> json) {
    return Denomination(
      value: _toDouble(json['value']) ??
          _toDouble(json['amount']) ??
          _toDouble(json['denomination']) ??
          0,
      cardId: json['card_id'] is int ? json['card_id'] as int : int.tryParse('${json['card_id']}'),
      usdValue:
          _toDouble(json['usd_value']) ?? _toDouble(json['value_usd']) ?? _toDouble(json['usd']),
    );
  }
}
