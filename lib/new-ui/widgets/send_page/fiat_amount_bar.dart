import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/new-ui/widgets/money/use_base_unit_provider.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class FiatAmountBar extends StatelessWidget {
  const FiatAmountBar({
    required this.fiatInputMode,
    required this.onSwitchButtonPressed,
    required this.cryptoAmount,
    required this.fiatAmount,
    super.key,
    this.onAllButtonPressed,
    this.allAmount,
    this.foregroundElementColor,
    this.textColor,
    this.allAmountColor,
    this.allAmountTextColor,
  });

  final bool fiatInputMode;
  final VoidCallback onSwitchButtonPressed;
  final VoidCallback? onAllButtonPressed;

  final Money cryptoAmount;
  final Money fiatAmount;
  final Money? allAmount;
  final Color? foregroundElementColor;
  final Color? textColor;
  final Color? allAmountColor;
  final Color? allAmountTextColor;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                ModernButton.svg(
                  backgroundColor: foregroundElementColor,
                  size: 28,
                  svgPath: "assets/new-ui/switch.svg",
                  iconSize: 18,
                  onPressed: onSwitchButtonPressed,
                  semanticLabel: S.of(context).switch_input_currency,
                ),
                // Announced as the converted value only: the switch button next to it already
                // exposes the same action, so this must not become a second control.
                Flexible(
                  child: GestureDetector(
                    onTap: onSwitchButtonPressed,
                    excludeFromSemantics: true,
                    child: MoneyText(
                      fiatInputMode ? cryptoAmount : fiatAmount,
                      fractionalDigits: fiatInputMode ? 6 : fiatAmount.currency.decimals,
                      trimZeros: fiatInputMode,
                      isHiddenAmount: false,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (allAmount != null)
            Row(
              spacing: 8,
              children: [
                // The caption is part of the chip's label below.
                ExcludeSemantics(
                  child: Text(
                    "${S.of(context).max}.",
                    style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999999)),
                  child: Material(
                    color: allAmountColor ??
                        foregroundElementColor ??
                        Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(99999),
                    child: Semantics(
                      button: true,
                      enabled: onAllButtonPressed != null,
                      label: S.of(context).max,
                      value: allAmount!.toLocalStringWithPrecision(
                        fractionalDigits: 8,
                        useBaseUnit: BaseUnit.useBaseUnitOf(context, allAmount!.currency),
                        locale: Localizations.localeOf(context).toString(),
                      ),
                      onTap: onAllButtonPressed,
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(99999),
                        onTap: onAllButtonPressed,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: MoneyText(
                            allAmount!,
                            showSymbol: false,
                            isHiddenAmount: false,
                            style: TextStyle(
                              color: allAmountTextColor ?? Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
}
