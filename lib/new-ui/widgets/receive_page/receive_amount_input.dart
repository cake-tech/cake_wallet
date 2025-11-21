import 'package:flutter/material.dart';

class ReceiveAmountInput extends StatelessWidget {
  const ReceiveAmountInput({super.key, required this.largeQrMode, required this.amountController, required this.selectedCurrency, required this.onCurrencySelectorTap});

  final bool largeQrMode;
  final TextEditingController amountController;
  final String selectedCurrency;
  final VoidCallback onCurrencySelectorTap;


  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 56,
              width: largeQrMode ? 250 : 160,
              decoration: BoxDecoration(
                color: largeQrMode
                    ? Theme.of(context).colorScheme.surfaceContainer
                    // no it can't just be transparent. might be framework bug actually
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  width: 2,
                ),
              ),
              child: AnimatedScale(
                duration: Duration(milliseconds: 300),
                scale: largeQrMode ? 1.3 : 1,
                curve: Curves.easeInCubic,
                child: TextField(
                  enabled: !largeQrMode,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  controller: amountController,
                  decoration: InputDecoration(
                      hint: Text(
                        "0.00000000",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
            GestureDetector(
              onTap: onCurrencySelectorTap,
              child: Container(
                height: 56,
                width: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0),
                    bottomLeft: Radius.circular(0),
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 4.0,
                  children: [
                    Text(
                      selectedCurrency.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
