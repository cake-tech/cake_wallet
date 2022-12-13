import 'dart:convert';
import 'package:cake_wallet/ionia/ionia_gift_card_instruction.dart';
import 'package:flutter/foundation.dart';

class IoniaGiftCard {
    IoniaGiftCard({
        required this.id,
        required this.merchantId,
        required this.legalName,
        required this.systemName,
        required this.barcodeUrl,
        required this.cardNumber,
        required this.cardPin,
        required this.instructions,
        required this.tip,
        required this.purchaseAmount,
        required this.actualAmount,
        required this.totalTransactionAmount,
        required this.totalDashTransactionAmount,
        required this.remainingAmount,
        required this.createdDateFormatted,
        required this.lastTransactionDateFormatted,
        required this.isActive,
        required this.isEmpty,
        required this.logoUrl});

    factory IoniaGiftCard.fromJsonMap(Map<String, dynamic> element) {
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
            totalDashTransactionAmount: (element['TotalDashTransactionAmount'] as double?) ?? 0.0,
            remainingAmount: element['RemainingAmount'] as double,
            isActive: element['IsActive'] as bool,
            isEmpty: element['IsEmpty'] as bool,
            logoUrl: element['LogoUrl'] as String,
            createdDateFormatted: element['CreatedDate'] as String,
            lastTransactionDateFormatted: element['LastTransactionDate'] as String,
            instructions: IoniaGiftCardInstruction.parseListOfInstructions(element['PaymentInstructions'] as String));
    }

    final int id;
    final int merchantId;
    final String legalName;
    final String systemName;
    final String barcodeUrl;
    final String cardNumber;
    final String cardPin;
    final List<IoniaGiftCardInstruction> instructions;
    final double tip;
    final double purchaseAmount;
    final double actualAmount;
    final double totalTransactionAmount;
    final double totalDashTransactionAmount;
    double remainingAmount;
    final String createdDateFormatted;
    final String lastTransactionDateFormatted;
    final bool isActive;
    final bool isEmpty;
    final String logoUrl;

}