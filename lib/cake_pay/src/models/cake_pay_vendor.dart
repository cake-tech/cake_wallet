import 'cake_pay_card.dart';

class CakePayVendor {
  final int id;
  final String name;
  final bool unavailable;
  final String? cakeWarnings;
  final String country;
  final CakePayCard? card;

  CakePayVendor({
    required this.id,
    required this.name,
    required this.unavailable,
    this.cakeWarnings,
    required this.country,
    this.card,
  });

  factory CakePayVendor.fromJson(Map<String, dynamic> json, String country) {
    final name = stripHtmlIfNeeded(json['name'] as String);

    var cardsJson = json['cards'] as List?;
    CakePayCard? cardForVendor;

    if (cardsJson != null && cardsJson.isNotEmpty) {
      try {
          cardForVendor = CakePayCard.fromJson(cardsJson
            .where((element) => element['country'] == country)
            .first as Map<String, dynamic>);
        } catch (_) {}
    }

    return CakePayVendor(
      id: json['id'] as int,
      name: name,
      unavailable: json['unavailable'] as bool? ?? false,
      cakeWarnings: json['cake_warnings'] as String?,
      country: country,
      card: cardForVendor,
    );
  }

  static String stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }
}
