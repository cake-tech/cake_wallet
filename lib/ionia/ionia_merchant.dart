import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'ionia_merchant.g.dart';

@HiveType(typeId: IoniaMerchant.typeId)
class IoniaMerchant  {
	IoniaMerchant({
		@required this.id,
		@required this.legalName,
		@required this.systemName,
		@required this.description,
		@required this.website,
		@required this.termsAndConditions,
		@required this.logoUrl,
		@required this.cardImageUrl,
		@required this.cardholderAgreement,
		@required this.purchaseFee,
		@required this.revenueShare,
		@required this.marketingFee,
		@required this.minimumDiscount,
		@required this.level1,
		@required this.level2, 
		@required this.level3,
		@required this.level4,
		@required this.level5,
		@required this.level6,
		@required this.level7,
		@required this.isActive,
		@required this.isDeleted,
		@required this.isOnline,
		@required this.isPhysical,
		@required this.isVariablePurchase,
		@required this.minimumCardPurchase,
		@required this.maximumCardPurchase,
		@required this.acceptsTips,
		@required this.createdDateFormatted,
		@required this.createdBy,
		@required this.isRegional,
		@required this.modifiedDateFormatted,
		@required this.modifiedBy,
		@required this.usageInstructions,
		@required this.usageInstructionsBak,
		@required this.paymentGatewayId,
		@required this.giftCardGatewayId,
		@required this.isHtmlDescription,
		@required this.purchaseInstructions,
		@required this.balanceInstructions,
		@required this.amountPerCard,
		@required this.processingMessage,
		@required this.hasBarcode,
		@required this.hasInventory,
		@required this.isVoidable,
		@required this.receiptMessage,
		@required this.cssBorderCode,
		@required this.paymentInstructions,
		@required this.alderSku,
		@required this.ngcSku,
		@required this.acceptedCurrency,
		@required this.deepLink,
		@required this.isPayLater
		});

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
      purchaseFee: element["PurchaseFee"] as double,
      revenueShare: element["RevenueShare"] as double,
      marketingFee: element["MarketingFee"] as double,
      minimumDiscount: element["MinimumDiscount"] as double,
      level1: element["Level1"] as double,
      level2: element["Level2"] as double,
      level3: element["Level3"] as double,
      level4: element["Level4"] as double,
      level5: element["Level5"] as double,
      level6: element["Level6"] as double,
      level7: element["Level7"] as double,
      isActive: element["IsActive"] as bool,
      isDeleted: element["IsDeleted"] as bool,
      isOnline: element["IsOnline"] as bool,
      isPhysical: element["IsPhysical"] as bool,
      isVariablePurchase: element["IsVariablePurchase"] as bool,
      minimumCardPurchase: element["MinimumCardPurchase"] as double,
      maximumCardPurchase: element["MaximumCardPurchase"] as double,
      acceptsTips: element["AcceptsTips"] as bool,
      createdDateFormatted: element["CreatedDate"] as String,
      createdBy: element["CreatedBy"] as int,
      isRegional: element["IsRegional"] as bool,
      modifiedDateFormatted: element["ModifiedDate"] as String,
      modifiedBy: element["ModifiedBy"] as int,
      usageInstructions: element["UsageInstructions"] as String,
      usageInstructionsBak: element["UsageInstructionsBak"] as String,
      paymentGatewayId: element["PaymentGatewayId"] as int,
      giftCardGatewayId: element["GiftCardGatewayId"] as int ,
      isHtmlDescription: element["IsHtmlDescription"] as bool,
      purchaseInstructions: element["PurchaseInstructions"] as String,
      balanceInstructions: element["BalanceInstructions"] as String,
      amountPerCard: element["AmountPerCard"] as double,
      processingMessage: element["ProcessingMessage"] as String,
      hasBarcode: element["HasBarcode"] as bool,
      hasInventory: element["HasInventory"] as bool,
      isVoidable: element["IsVoidable"] as bool,
      receiptMessage: element["ReceiptMessage"] as String,
      cssBorderCode: element["CssBorderCode"] as String,
      paymentInstructions: element["PaymentInstructions"] as String,
      alderSku: element["AlderSku"] as String,
      ngcSku: element["NgcSku"] as String,
      acceptedCurrency: element["AcceptedCurrency"] as String,
      deepLink: element["DeepLink"] as String,
      isPayLater: element["IsPayLater"] as bool);
	}

  static const typeId = 10;
  static const boxName = 'IoniaMerchant';

  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String legalName;
	
  @HiveField(2)
  final String systemName;
	
  @HiveField(3)
  final String description;
	
  @HiveField(4)
  final String website;
	
  @HiveField(5)
  final String termsAndConditions;
	
  @HiveField(6)
  final String logoUrl;
	
  @HiveField(7)
  final String cardImageUrl;
	
  @HiveField(8)
  final String cardholderAgreement;
	
  @HiveField(9)
  final double purchaseFee;
	
  @HiveField(10)
  final double revenueShare;
	
  @HiveField(11)
  final double marketingFee;
	
  @HiveField(12)
  final double minimumDiscount;
	
  @HiveField(13)
  final double level1;
	
  @HiveField(14)
  final double level2;
	
  @HiveField(15)
  final double level3;
	
  @HiveField(16)
  final double level4;
	
  @HiveField(17)
  final double level5;
	
  @HiveField(18)
  final double level6;
	
  @HiveField(19)
  final double level7;
	
  @HiveField(20)
  final bool isActive;
	
  @HiveField(21)
  final bool isDeleted;
	
  @HiveField(22)
  final bool isOnline;
	
  @HiveField(23)
  final bool isPhysical;
	
  @HiveField(24)
  final bool isVariablePurchase;
	
  @HiveField(25)
  final double minimumCardPurchase;
	
  @HiveField(26)
  final double maximumCardPurchase;
	
  @HiveField(27)
  final bool acceptsTips;
	
  @HiveField(28)
  final String createdDateFormatted;
	
  @HiveField(29)
  final int createdBy;
	
  @HiveField(30)
  final bool isRegional;
	
  @HiveField(31)
  final String modifiedDateFormatted;
	
  @HiveField(32)
  final int modifiedBy;
	
  @HiveField(33)
  final String usageInstructions;
	
  @HiveField(34)
  final String usageInstructionsBak;
	
  @HiveField(35)
  final int paymentGatewayId;
	
  @HiveField(36)
  final int giftCardGatewayId;
	
  @HiveField(37)
  final bool isHtmlDescription;
	
  @HiveField(38)
  final String purchaseInstructions;
	
  @HiveField(39)
  final String balanceInstructions;
	
  @HiveField(40)
  final double amountPerCard;
	
  @HiveField(41)
  final String processingMessage;
	
  @HiveField(42)
  final bool hasBarcode;
	
  @HiveField(43)
  final bool hasInventory;
	
  @HiveField(44)
  final bool isVoidable;
	
  @HiveField(45)
  final String receiptMessage;
	
  @HiveField(46)
  final String cssBorderCode;
	
  @HiveField(47)
  final String paymentInstructions;
	
  @HiveField(48)
  final String alderSku;
	
  @HiveField(49)
  final String ngcSku;
	
  @HiveField(50)
  final String acceptedCurrency;
	
  @HiveField(51)
  final String deepLink;
	
  @HiveField(52)
  final bool isPayLater;
  
}
