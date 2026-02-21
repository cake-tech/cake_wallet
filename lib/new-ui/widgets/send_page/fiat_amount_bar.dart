import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class FiatAmountBar extends StatelessWidget {
  const FiatAmountBar(
      {super.key,
      required this.fiatInputMode,
      required this.onSwitchButtonPressed,
      this.onAllButtonPressed,
      required this.cryptoAmount,
      required this.fiatAmount,
      required this.cryptoCurrency,
      required this.fiatCurrency,
      this.allAmount,
      this.foregroundElementColor,
      this.textColor});

  final bool fiatInputMode;
  final VoidCallback onSwitchButtonPressed;
  final VoidCallback? onAllButtonPressed;

  final String cryptoAmount;
  final String fiatAmount;
  final String cryptoCurrency;
  final String fiatCurrency;
  final String? allAmount;
  final Color? foregroundElementColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
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
            ),
            Observer(
                builder: (_) => GestureDetector(
                  onTap: onSwitchButtonPressed,
                  child: Text(
                        fiatInputMode
                            ? "${cryptoAmount.isEmpty ? "0" : cryptoAmount.withMaxDecimals(8)} ${cryptoCurrency}"
                            : "${fiatAmount.isEmpty ? "0" : fiatAmount} ${fiatCurrency}",
                        style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSurface),
                      ),
                )),
          ],
        ),
        if (allAmount != null && allAmount!.isNotEmpty)
          Row(
            spacing: 8,
            children: [
              Text(
                "${S.of(context).max}.",
                style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSurface),
              ),
              Material(
                  color: foregroundElementColor ?? Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(99999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99999),
                    onTap: onAllButtonPressed,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                      child: Text(
                        formatAmount(allAmount!),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ))
            ],
          )
      ],
    );
  }

  String formatAmount(String amount) {
    try {
      return double.parse(amount).toStringAsPrecision(8).replaceFirst(RegExp(r"\.?0+$"), "");
    } catch(e) {
      return amount;
    }
  }
}
