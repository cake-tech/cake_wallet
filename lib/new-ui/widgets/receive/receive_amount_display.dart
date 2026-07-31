import "package:flutter/material.dart";

class ReceiveAmountDisplay extends StatelessWidget {
  const ReceiveAmountDisplay({
    required this.displayAmount,
    required this.cryptoSymbol,
    required this.fiatAmount,
    required this.fiatSymbol,
    required this.showFiat,
    required this.largeQrMode,
    super.key,
  });

  final String displayAmount;
  final String cryptoSymbol;
  final String fiatAmount;
  final String fiatSymbol;
  final bool showFiat;
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
                  if (showFiat)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        "$fiatAmount $fiatSymbol",
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
    );
  }
}
