import 'cake_pay_card.dart';

class CakePayVendor {
  final int id;
  final String name;
  final bool unavailable;
  final String? cakeWarnings;
  final List<String> countries;
  final CakePayCard? card;

  CakePayVendor({
    required this.id,
    required this.name,
    required this.unavailable,
    this.cakeWarnings,
    required this.countries,
    this.card,
  });

  factory CakePayVendor.fromJson(Map<String, dynamic> json) {
    final name = stripHtmlIfNeeded(json['name'] as String);

    var cardsJson = json['cards'] as List?;
    CakePayCard? firstCard;

    if (cardsJson != null && cardsJson.isNotEmpty) {
      firstCard = CakePayCard.fromJson(cardsJson.first as Map<String, dynamic>);
    }

    return CakePayVendor(
      id: json['id'] as int,
      name: name,
      unavailable: json['unavailable'] as bool? ?? false,
      cakeWarnings: json['cake_warnings'] as String?,
      countries: List<String>.from(json['countries'] as List? ?? []),
      card: firstCard,
    );
  }

  static String stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }
}
