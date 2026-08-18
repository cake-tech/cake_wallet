import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class ReceiveAmountDisplay extends StatelessWidget {
  const ReceiveAmountDisplay({
    required this.displayAmount,
    required this.cryptoSymbol,
    required this.fiatEquivalent,
    required this.largeQrMode,
    super.key,
  });

  final String displayAmount;
  final String cryptoSymbol;
  final Money? fiatEquivalent;
  final bool largeQrMode;

  @override
  Widget build(BuildContext context) {
    final hidden = largeQrMode || displayAmount.isEmpty;
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
                        child: Row(
                          spacing: 8,
                          children: [
                            Text(
                              displayAmount,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              cryptoSymbol,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (fiatEquivalent != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          "${fiatEquivalent!.toStringWithPrecision()} ${fiatEquivalent!.currency.symbol}",
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
