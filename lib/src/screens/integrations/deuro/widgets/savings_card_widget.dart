import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class SavingsCard extends StatelessWidget {
  final bool isDarkTheme;
  final String interestRate;
  final String savingsBalance;
  final CryptoCurrency currency;
  final VoidCallback onAddSavingsPressed;
  final VoidCallback onRemoveSavingsPressed;

  const SavingsCard({
    super.key,
    required this.isDarkTheme,
    required this.interestRate,
    required this.savingsBalance,
    required this.currency,
    required this.onAddSavingsPressed,
    required this.onRemoveSavingsPressed,
  });

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            isDarkTheme
                ? CustomThemeColors.cardGradientColorPrimaryDark
                : CustomThemeColors.cardGradientColorPrimaryLight,
            isDarkTheme
                ? CustomThemeColors.cardGradientColorSecondaryDark
                : CustomThemeColors.cardGradientColorSecondaryLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.only(
          top: 10,
          left: 12,
          right: 12,
          bottom: 10,
        ),
        child: Column(
          children: [
            getAssetBalanceRow(context,
                title: S.of(context).deuro_savings_balance,
                subtitle: savingsBalance,
                currency: currency),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Current APY',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                      softWrap: true,
                    ),
                  ),
                  Text(
                    interestRate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: getButton(
                    context,
                    label: S.of(context).deuro_savings_add,
                    imagePath: 'assets/images/received.png',
                    onPressed: onAddSavingsPressed,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: getButton(
                    context,
                    label: S.of(context).deuro_savings_remove,
                    imagePath: 'assets/images/upload.png',
                    onPressed: onRemoveSavingsPressed,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ));

  static Widget getButton(
    BuildContext context, {
    required String label,
    required String imagePath,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color color,
  }) =>
      Semantics(
        label: label,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(0),
              width: 0,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  height: 30,
                  width: 30,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      );

  static Widget getAssetBalanceRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required CryptoCurrency currency,
    bool hideSymbol = false,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1,
                    ),
              ),
              SizedBox(height: 6),
              AutoSizeText(
                subtitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      height: 1,
                    ),
                maxLines: 1,
                textAlign: TextAlign.start,
              ),
            ],
          ),
          SizedBox(
            //width: min(MediaQuery.of(context).size.width * 0.2, 100),
            child: Center(
              child: Column(
                children: [
                  CakeImageWidget(
                    imageUrl: currency.iconPath,
                    height: 40,
                    width: 40,
                    errorWidget: Container(
                      height: 30.0,
                      width: 30.0,
                      child: Center(
                        child: Text(
                          currency.title
                              .substring(0, min(currency.title.length, 2)),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                    ),
                  ),
                  if (!hideSymbol) ...[
                    const SizedBox(height: 10),
                    Text(
                      currency.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1,
                          ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      );
}
