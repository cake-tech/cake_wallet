import 'package:flutter/foundation.dart';
import 'package:cake_wallet/ionia/ionia_gift_card_instruction.dart';

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
		@required this.instructions,
		@required this.alderSku,
		@required this.ngcSku,
		@required this.acceptedCurrency,
		@required this.deepLink,
		@required this.isPayLater,
        @required this.savingsPercentage});

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
            instructions: IoniaGiftCardInstruction.parseListOfInstructions(element['PaymentInstructions'] as String),
            alderSku: element["AlderSku"] as String,
            ngcSku: element["NgcSku"] as String,
            acceptedCurrency: element["AcceptedCurrency"] as String,
            deepLink: element["DeepLink"] as String,
            isPayLater: element["IsPayLater"] as bool,
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
    final double purchaseFee;
    final double revenueShare;
    final double marketingFee;
    final double minimumDiscount;
    final double level1;
    final double level2;
    final double level3;
    final double level4;
    final double level5;
    final double level6;
    final double level7;
    final bool isActive;
    final bool isDeleted;
    final bool isOnline;
    final bool isPhysical;
    final bool isVariablePurchase;
    final double minimumCardPurchase;
    final double maximumCardPurchase;
    final bool acceptsTips;
    final String createdDateFormatted;
    final int createdBy;
    final bool isRegional;
    final String modifiedDateFormatted;
    final int modifiedBy;
    final String usageInstructions;
    final String usageInstructionsBak;
    final int paymentGatewayId;
    final int giftCardGatewayId;
    final bool isHtmlDescription;
    final String purchaseInstructions;
    final String balanceInstructions;
    final double amountPerCard;
    final String processingMessage;
    final bool hasBarcode;
    final bool hasInventory;
    final bool isVoidable;
    final String receiptMessage;
    final String cssBorderCode;
    final List<IoniaGiftCardInstruction> instructions;
    final String alderSku;
    final String ngcSku;
    final String acceptedCurrency;
    final String deepLink;
    final bool isPayLater;
    final double savingsPercentage;

    double get discount => savingsPercentage;
  
}
