import 'dart:convert';

import 'package:cake_wallet/ionia/ionia_gift_card_instruction.dart';
import 'package:cake_wallet/generated/i18n.dart';

import 'cake_pay_card.dart';

class IoniaMerchant {
  IoniaMerchant(
      {required this.id,
      required this.legalName,
      required this.systemName,
      required this.description,
      required this.website,
      required this.termsAndConditions,
      required this.logoUrl,
      required this.cardImageUrl,
      required this.cardholderAgreement,
      required this.isActive,
      required this.isOnline,
      required this.isPhysical,
      required this.isVariablePurchase,
      required this.minimumCardPurchase,
      required this.maximumCardPurchase,
      required this.acceptsTips,
      required this.createdDateFormatted,
      required this.modifiedDateFormatted,
      required this.usageInstructions,
      required this.usageInstructionsBak,
      required this.hasBarcode,
      required this.instructions,
      required this.savingsPercentage});

  factory IoniaMerchant.fromJsonMap(Map<String, dynamic> element) {
    return IoniaMerchant(
        id: element["Id"] as int,
        legalName: element["LegalName"] as String,
        systemName: element["SystemName"] as String,
        description: element["Description"] as String,
        website: element["Website"] as String,
        termsAndConditions: element["TermsAndConditions"] as String,
        logoUrl: element["LogoUrl"] as String,
        cardImageUrl: element["CardImageUrl"] as String,
        cardholderAgreement: element["CardholderAgreement"] as String,
        isActive: element["IsActive"] as bool?,
        isOnline: element["IsOnline"] as bool,
        isPhysical: element["IsPhysical"] as bool,
        isVariablePurchase: element["IsVariablePurchase"] as bool,
        minimumCardPurchase: element["MinimumCardPurchase"] as double,
        maximumCardPurchase: element["MaximumCardPurchase"] as double,
        acceptsTips: element["AcceptsTips"] as bool,
        createdDateFormatted: element["CreatedDate"] as String?,
        modifiedDateFormatted: element["ModifiedDate"] as String?,
        usageInstructions: element["UsageInstructions"] as String?,
        usageInstructionsBak: element["UsageInstructionsBak"] as String?,
        hasBarcode: element["HasBarcode"] as bool,
        instructions: IoniaGiftCardInstruction.parseListOfInstructions(
            element['PaymentInstructions'] as String),
        savingsPercentage: element["SavingsPercentage"] as double);
  }

  final int id;
  final String legalName;
  final String systemName;
  final String description;
  final String website;
  final String termsAndConditions;
  final String logoUrl;
  final String cardImageUrl;
  final String cardholderAgreement;
  final bool? isActive;
  final bool isOnline;
  final bool? isPhysical;
  final bool isVariablePurchase;
  final double minimumCardPurchase;
  final double maximumCardPurchase;
  final bool acceptsTips;
  final String? createdDateFormatted;
  final String? modifiedDateFormatted;
  final String? usageInstructions;
  final String? usageInstructionsBak;
  final bool hasBarcode;
  final List<IoniaGiftCardInstruction> instructions;
  final double savingsPercentage;

  double get discount => savingsPercentage;

  String get avaibilityStatus {
    var status = '';

    if (isOnline) {
      status += S.current.online;
    }

    if (isPhysical ?? false) {
      if (status.isNotEmpty) {
        status = '$status & ';
      }

      status = '${status}${S.current.in_store}';
    }

    return status;
  }
}

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
    final decodedName = fixEncoding(name);

    var cardsJson = json['cards'] as List?;
    CakePayCard? firstCard;

    if (cardsJson != null && cardsJson.isNotEmpty) {
      firstCard = CakePayCard.fromJson(cardsJson.first as Map<String, dynamic>);
    }

    return CakePayVendor(
      id: json['id'] as int,
      name: decodedName,
      unavailable: json['unavailable'] as bool? ?? false,
      cakeWarnings: json['cake_warnings'] as String?,
      countries: List<String>.from(json['countries'] as List? ?? []),
      card: firstCard,
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
