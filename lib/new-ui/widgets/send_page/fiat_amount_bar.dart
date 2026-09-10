import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:flutter/material.dart";

class FiatAmountBar extends StatelessWidget {
  const FiatAmountBar({
    required this.fiatInputMode,
    required this.onSwitchButtonPressed,
    required this.cryptoAmount,
    required this.fiatAmount,
    required this.cryptoCurrencySymbol,
    required this.fiatCurrencySymbol,
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

  final String cryptoAmount;
  final String fiatAmount;
  final String cryptoCurrencySymbol;
  final String fiatCurrencySymbol;
  final String? allAmount;
  final Color? foregroundElementColor;
  final Color? textColor;
  final Color? allAmountColor;
  final Color? allAmountTextColor;

  @override
  Widget build(BuildContext context) {
    final convertedAmount = fiatInputMode
        ? "${cryptoAmount.isEmpty ? "0" : cryptoAmount.withMaxDecimals(8)} $cryptoCurrencySymbol"
        : "${fiatAmount.isEmpty ? "0" : fiatAmount} $fiatCurrencySymbol";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            Semantics(
              label: convertedAmount,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onSwitchButtonPressed,
                child: Text(
                  convertedAmount,
                  style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
          ],
        ),
        if (allAmount != null && allAmount!.isNotEmpty)
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
                    value: _formatAmount(allAmount!),
                    onTap: onAllButtonPressed,
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(99999),
                      onTap: onAllButtonPressed,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          _formatAmount(allAmount!),
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

  String _formatAmount(String amount) {
    try {
      return double.parse(amount).toStringAsPrecision(8).replaceFirst(RegExp(r"\.?0+$"), "");
    } catch (e) {
      return amount;
    }
  }
}
