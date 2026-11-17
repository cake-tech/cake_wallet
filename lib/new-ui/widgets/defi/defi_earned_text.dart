import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/themes/core/custom_theme_colors.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class DefiEarnedText extends StatelessWidget {
  const DefiEarnedText(
    this.earned, {
    required this.fiatRate,
    required this.style,
    this.isHiddenAmount,
    super.key,
  });

  final Money earned;
  final ExchangeRate? fiatRate;
  final TextStyle style;
  final bool? isHiddenAmount;

  @override
  Widget build(BuildContext context) {
    final fiat = fiatRate?.convert(earned);
    final earnedStyle = style.copyWith(
      color: earned.isNegative ? Theme.of(context).colorScheme.error : CustomThemeColors.syncGreen,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!earned.isNegative) Text("+", style: earnedStyle),
        MoneyText(
          fiat ?? earned,
          fractionalDigits: fiat == null ? 8 : 2,
          trimZeros: fiat == null,
          isHiddenAmount: isHiddenAmount,
          style: earnedStyle,
        ),
      ],
    );
  }
}
