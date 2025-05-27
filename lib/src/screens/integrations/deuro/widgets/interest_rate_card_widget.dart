import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class InterestRateCardWidget extends StatelessWidget {
  InterestRateCardWidget({
    required this.title,
    required this.interestRate,
    this.customBorder,
    this.shadowSpread,
    this.shadowBlur,
    super.key,
    this.marginV,
    this.marginH,
    required this.isDarkTheme,
  });

  final String title;
  final String interestRate;
  final double? customBorder;
  final double? marginV;
  final double? marginH;
  final double? shadowSpread;
  final double? shadowBlur;
  final bool isDarkTheme;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        margin: EdgeInsets.symmetric(
            horizontal: marginH ?? 20, vertical: marginV ?? 5),
        width: double.infinity,
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
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    interestRate,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                    softWrap: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
