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
        final cards = cardsJson
            .map((cardJson) => CakePayCard.fromJson(cardJson as Map<String, dynamic>))
            .toList();
        final cardsForSelectedCountry =
            cards.where((card) => Country.normalizeName(card.country ?? '') == country).toList();

        if (cardsForSelectedCountry.isNotEmpty) {
          final isPrepaid =
              cardsForSelectedCountry.every((card) => card.type == CakePayCardType.prepaid);

          if (isPrepaid) {
            final firstCard = cardsForSelectedCountry.first;
            final prepaidRanges = cardsForSelectedCountry.map(PrepaidRange.fromCard).toList()
              ..sort((a, b) => a.minValue.compareTo(b.minValue));

            cardForVendor = firstCard.copyWith(prepaidRange: prepaidRanges);
          } else {
            cardForVendor = cardsForSelectedCountry.first;
          }
        }
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
