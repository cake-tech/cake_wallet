import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class LoanDetailsSheet extends BaseBottomSheet {
  const LoanDetailsSheet({
    super.key,
    required this.loanAmount,
    required this.retainedReserve,
    required this.liquidationPrice,
    required this.expectedInterest,
    required this.annualInterest,
    required this.originalPosition,
    required this.expiration,
    required this.currency,
    required super.titleText,
    required super.footerType,
    required super.maxHeight,
  });

  final String loanAmount;
  final String retainedReserve;
  final String liquidationPrice;
  final String expectedInterest;
  final String annualInterest;
  final String originalPosition;
  final CryptoCurrency currency;
  final int expiration;

  @override
  Widget contentWidget(BuildContext context) =>
      LoanDetailsWidget(
        loanAmount: loanAmount,
        retainedReserve: retainedReserve,
        liquidationPrice: liquidationPrice,
        expectedInterest: expectedInterest,
        annualInterest: annualInterest,
        originalPosition: originalPosition,
        expiration: expiration,
        currency: currency,
      );
}

class LoanDetailsWidget extends StatelessWidget {
  const LoanDetailsWidget({
    super.key,
    required this.loanAmount,
    required this.retainedReserve,
    required this.liquidationPrice,
    required this.expectedInterest,
    required this.annualInterest,
    required this.originalPosition,
    required this.expiration,
    required this.currency,
  });

  final String loanAmount;
  final String retainedReserve;
  final String liquidationPrice;
  final String expectedInterest;
  final String annualInterest;
  final String originalPosition;
  final CryptoCurrency currency;
  final int expiration;

  int get expiryDays =>
      DateTime
          .fromMillisecondsSinceEpoch(expiration * 1000)
          .difference(DateTime.now())
          .inDays;

  @override
  Widget build(BuildContext context) =>
      Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Theme
              .of(context)
              .colorScheme
              .surfaceContainerLowest,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                context.customColors.cardGradientColorPrimary,
                context.customColors.cardGradientColorSecondary,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              getRow(context, "Loan amount", "${loanAmount} ${currency.title}"),
              getRow(context, "Retained Reserve", "${retainedReserve} ${currency.title}"),
              getRow(context, "Liquidation price", "${liquidationPrice} ${currency.title}"),
              getRow(context, "Expected interest", "${expectedInterest} ${currency.title}"),
              getRow(context, "Annual Interest", "${annualInterest}%"),
              getRow(context, "Original Position", "${originalPosition}", true),
            ],
          ),
        ),
      );

  static Widget getRow(BuildContext context, String label, String value,
      [bool isAddress = false]) =>
      Padding(
        padding: EdgeInsets.only(top: 10, bottom: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              isAddress ? getShortAddress(value) : value,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface,
                height: 1,
              ),
            )
          ],
        ),
      );

  static String getShortAddress(String address) =>
      "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
}
