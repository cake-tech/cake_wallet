import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SavingsCard extends StatelessWidget {
  const SavingsCard({
    super.key,
    required this.interestRate,
    required this.savingsBalance,
    required this.currency,
    required this.onAddSavingsPressed,
    required this.onRemoveSavingsPressed,
    required this.onApproveSavingsPressed,
    required this.onTooltipPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.fiatSavingsBalance,
    this.fiatCurrency,
    required this.currentTheme,
  });

  final bool isEnabled;
  final bool isLoading;
  final String interestRate;
  final String savingsBalance;
  final String? fiatSavingsBalance;
  final FiatCurrency? fiatCurrency;
  final CryptoCurrency currency;
  final VoidCallback onAddSavingsPressed;
  final VoidCallback onRemoveSavingsPressed;
  final VoidCallback onApproveSavingsPressed;
  final VoidCallback onTooltipPressed;
  final MaterialThemeBase currentTheme;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Current APR', // ToDo: Localize
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                    softWrap: true,
                  ),
                ),
                Text(
                  interestRate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                  softWrap: true,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  currentTheme.customColors.cardGradientColorPrimary,
                  currentTheme.customColors.cardGradientColorSecondary,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: getAssetBalanceRow(
                    context,
                    title: S.of(context).deuro_savings_balance,
                    amount: savingsBalance,
                    fiatAmount: fiatSavingsBalance,
                    currency: currency,
                    fiatCurrency: fiatCurrency,
                    hideSymbol: false,
                    onTooltipPressed: onTooltipPressed,
                  ),
                ),
                isLoading
                    ? CupertinoActivityIndicator(color: Theme.of(context).colorScheme.onSurface)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: isEnabled
                            ? [
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
                              ]
                            : [
                                Expanded(
                                  child: getButton(
                                    context,
                                    label: S.of(context).deuro_savings_approve_app,
                                    onPressed: onApproveSavingsPressed,
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    icon: Icons.check,
                                  ),
                                )
                              ],
                      ),
              ],
            ),
          ),
        ]),
      );

  static Widget getButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color color,
    String? imagePath,
    IconData? icon,
    bool enabled = true,
    double iconSize = 24,
  }) {
    backgroundColor = enabled ? backgroundColor : backgroundColor.withAlpha(130);
    color = enabled ? color : color.withAlpha(130);

    return Semantics(
      label: label,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(0),
            width: 0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath != null) ...[
                Image.asset(imagePath, height: iconSize, width: iconSize, color: color),
                const SizedBox(width: 8),
              ],
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: color),
                const SizedBox(width: 8),
              ],
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
  }

  static Widget getAssetBalanceRow(
    BuildContext context, {
    required String title,
    required String amount,
    required CryptoCurrency currency,
    bool hideSymbol = true,
    VoidCallback? onTooltipPressed,
    FiatCurrency? fiatCurrency,
    String? fiatAmount,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1,
                        ),
                  ),
                  if (onTooltipPressed != null)
                    Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: InkWell(
                        onTap: onTooltipPressed,
                        child: Icon(
                          CupertinoIcons.question_circle,
                          size: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6),
              AutoSizeText(
                amount,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      height: 1,
                    ),
                maxLines: 1,
                textAlign: TextAlign.start,
              ),
              if (fiatCurrency != null)
                AutoSizeText(
                  "${fiatCurrency.title} $fiatAmount",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        height: 1.5,
                      ),
                  maxLines: 1,
                  textAlign: TextAlign.start,
                ),
            ],
          ),
          SizedBox(
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
                          currency.title.substring(0, min(currency.title.length, 2)),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    const SizedBox(height: 3),
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
