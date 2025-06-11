import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_card_widget.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class InterestCardWidget extends StatelessWidget {
  InterestCardWidget({
    required this.title,
    required this.collectedInterest,
    super.key,
    required this.isDarkTheme,
  });

  final String title;
  final String collectedInterest;
  final bool isDarkTheme;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
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
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SavingsCard.getAssetBalanceRow(
                context,
                title: title,
                subtitle: collectedInterest,
                currency: CryptoCurrency.deuro,
                hideSymbol: true,
              ),
              SizedBox(height: 10),
              SavingsCard.getButton(
                context,
                label: "Collect",
                imagePath: 'assets/images/received.png',
                onPressed: () {},
                backgroundColor: Theme.of(context).colorScheme.primary,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
