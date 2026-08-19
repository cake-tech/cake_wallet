import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class ReceiveAmountDisplay extends StatelessWidget {
  const ReceiveAmountDisplay({
    required this.amount,
    required this.fiatEquivalent,
    required this.largeQrMode,
    super.key,
  });

  final Money? amount;
  final Money? fiatEquivalent;
  final bool largeQrMode;

  @override
  Widget build(BuildContext context) {
    final amount = this.amount;
    final fiatEquivalent = this.fiatEquivalent;
    final hidden = largeQrMode || amount == null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      opacity: hidden ? 0 : 1,
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        heightFactor: hidden ? 0 : 1,
        alignment: Alignment.topCenter,
        // Amount, currency symbol and fiat equivalent describe one value, so
        // they are announced as a single node.
        child: MergeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  spacing: 4,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: amount == null
                            ? const SizedBox.shrink()
                            : MoneyText(
                                amount,
                                isHiddenAmount: false,
                                fractionalDigits: 20,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    if (fiatEquivalent != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: MoneyText(
                          fiatEquivalent,
                          isHiddenAmount: false,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
