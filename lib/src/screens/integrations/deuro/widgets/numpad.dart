import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberPad extends StatelessWidget {
  final VoidCallback? onDecimalPressed;
  final VoidCallback onDeletePressed;
  final void Function(int index) onNumberPressed;
  final FocusNode focusNode;

  const NumberPad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
    required this.focusNode,
    this.onDecimalPressed,
  });

  @override
  Widget build(BuildContext context) => KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: (keyEvent) {
          if (keyEvent is KeyDownEvent) {
            if (keyEvent.logicalKey.keyLabel == "Backspace") {
              return onDeletePressed();
            }

            if ([".", ","].contains(keyEvent.logicalKey.keyLabel) &&
                onDecimalPressed != null) {
              return onDecimalPressed!();
            }

            int? number = int.tryParse(keyEvent.character ?? '');
            if (number != null) return onNumberPressed(number);
          }
        },
        child: SizedBox(
          height: 300,
          child: GridView.count(
            childAspectRatio: 2,
            shrinkWrap: true,
            crossAxisCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(12, (index) {
              if (index == 9) {
                if (onDecimalPressed == null) return Container();
                return InkWell(
                  onTap: onDecimalPressed,
                  child: Center(
                    child: Text(
                      '.',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else if (index == 10) {
                index = 0;
              } else if (index == 11) {
                return MergeSemantics(
                  child: Container(
                    child: Semantics(
                      label: S.of(context).delete,
                      button: true,
                      onTap: onDeletePressed,
                      child: TextButton(
                        onPressed: onDeletePressed,
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Colors.transparent,
                          shape: CircleBorder(),
                        ),
                        child: Image.asset(
                          'assets/images/delete_icon.png',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                index++;
              }

              return InkWell(
                onTap: () => onNumberPressed(index),
                child: Center(
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 30,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ),
        ),
      );
}
