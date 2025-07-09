import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_card_widget.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class InterestCardWidget extends StatelessWidget {
  const InterestCardWidget({
    required this.title,
    required this.accruedInterest,
    required this.isDarkTheme,
    required this.isEnabled,
    required this.onCollectInterest,
    required this.onReinvestInterest,
    required this.onTooltipPressed,
    this.fiatAccruedInterest,
    this.fiatCurrency,
  });

  final String title;
  final String accruedInterest;
  final String? fiatAccruedInterest;
  final FiatCurrency? fiatCurrency;
  final bool isDarkTheme;
  final bool isEnabled;
  final VoidCallback onCollectInterest;
  final VoidCallback onReinvestInterest;
  final VoidCallback onTooltipPressed;

  @override
  Widget build(BuildContext context) => Stack(children: [
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
                  amount: accruedInterest,
                  fiatAmount: fiatAccruedInterest,
                  currency: CryptoCurrency.deuro,
                  fiatCurrency: fiatCurrency,
                  hideSymbol: false,
                  onTooltipPressed: onTooltipPressed
                ),
                SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: SavingsCard.getButton(
                      context,
                      imagePath: 'assets/images/collect_interest.png',
                      label: S.of(context).deuro_collect_interest,
                      onPressed: onCollectInterest,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      color: Theme.of(context).colorScheme.onPrimary,
                      enabled: isEnabled,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SavingsCard.getButton(
                      context,
                      label: S.of(context).deuro_reinvest_interest,
                      icon: Icons.account_balance_outlined,
                      onPressed: onReinvestInterest,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      enabled: isEnabled,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]);
}
