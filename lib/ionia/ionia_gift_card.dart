import 'dart:convert';

import 'package:flutter/foundation.dart';

class IoniaGiftCardInstruction {
    IoniaGiftCardInstruction(this.header, this.body);

    factory IoniaGiftCardInstruction.fromJsonMap(Map<String, dynamic> element) {
        return IoniaGiftCardInstruction(
            element['header'] as String,
            element['body'] as String);
    }

    final String header;
    final String body;
}

class IoniaGiftCard {
    IoniaGiftCard({
        @required this.id,
        @required this.merchantId,
        @required this.legalName,
        @required this.systemName,
        @required this.barcodeUrl,
        @required this.cardNumber,
        @required this.cardPin,
        @required this.usageInstructions,
        @required this.balanceInstructions,
        @required this.paymentInstructions,
        @required this.cardImageUrl,
        @required this.tip,
        @required this.purchaseAmount,
        @required this.actualAmount,
        @required this.totalTransactionAmount,
        @required this.totalDashTransactionAmount,
        @required this.remainingAmount,
        @required this.createdDateFormatted,
        @required this.lastTransactionDateFormatted,
        @required this.isActive,
        @required this.isEmpty,
        @required this.logoUrl});

    factory IoniaGiftCard.fromJsonMap(Map<String, dynamic> element) {
        final decodedInstructions = json.decode(element['UsageInstructions'] as String) as Map<String, dynamic>;
        final instruction = decodedInstructions['instruction'] as List<dynamic>;
        final instructions = instruction
                .map((dynamic e) =>IoniaGiftCardInstruction.fromJsonMap(e as Map<String, dynamic>))
                .toList();
        return IoniaGiftCard(
            id: element['Id'] as int,
            merchantId: element['MerchantId'] as int,
            legalName: element['LegalName'] as String,
            systemName: element['SystemName'] as String,
            barcodeUrl: element['BarcodeUrl'] as String,
            cardNumber: element['CardNumber'] as String,
            cardPin: element['CardPin'] as String,
            tip: element['Tip'] as double,
            purchaseAmount: element['PurchaseAmount'] as double,
            actualAmount: element['ActualAmount'] as double,
            totalTransactionAmount: element['TotalTransactionAmount'] as double,
            totalDashTransactionAmount: element['TotalDashTransactionAmount'] as double,
            remainingAmount: element['RemainingAmount'] as double,
            isActive: element['IsActive'] as bool,
            isEmpty: element['IsEmpty'] as bool,
            logoUrl: element['LogoUrl'] as String,
            createdDateFormatted: element['CreatedDate'] as String,
            lastTransactionDateFormatted: element['LastTransactionDate'] as String,
            usageInstructions: instructions);
    }

    final int id;
    final int merchantId;
    final String legalName;
    final String systemName;
    final String barcodeUrl;
    final String cardNumber;
    final String cardPin;
    final List<IoniaGiftCardInstruction> usageInstructions;
    final Map<String, dynamic> balanceInstructions;
    final Map<String, dynamic> paymentInstructions;
    final String cardImageUrl;
    final double tip;
    final double purchaseAmount;
    final double actualAmount;
    final double totalTransactionAmount;
    final double totalDashTransactionAmount;
    final double remainingAmount;
    final String createdDateFormatted;
    final String lastTransactionDateFormatted;
    final bool isActive;
    final bool isEmpty;
    final String logoUrl;
}