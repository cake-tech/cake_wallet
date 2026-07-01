import 'package:cake_wallet/entities/country.dart';
import 'package:cw_core/utils/print_verbose.dart';

import 'cake_pay_card.dart';

class CakePayVendor {
  final int id;
  final String name;
  final bool available;
  final String? cakeWarnings;
  final String country;
  final CakePayCard? card;

  CakePayVendor({
    required this.id,
    required this.name,
    required this.available,
    this.cakeWarnings,
    required this.country,
    this.card,
  });

  factory CakePayVendor.fromJson(Map<String, dynamic> json) {
    final name = stripHtmlIfNeeded(json['name'] as String);

    final parsedCountry = json['country'] as String;
    final country = Country.normalizeName(parsedCountry);

    var cardsJson = json['cards'] as List?;
    CakePayCard? cardForVendor;

    if (cardsJson != null && cardsJson.isNotEmpty) {
      try {
        cardForVendor = CakePayCard.fromJson(cardsJson.firstWhere((card) {
          return Country.normalizeName(card['country'] as String) == country;
        }) as Map<String, dynamic>);
      } catch (e) {
        printV('Error parsing card for vendor: $e');
      }
    }

    return CakePayVendor(
      id: json['id'] as int,
      name: name,
      available: json['available'] as bool? ?? false,
      cakeWarnings: json['cake_warnings'] as String?,
      country: country,
      card: cardForVendor,
    );
  }

  static String stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }
}
