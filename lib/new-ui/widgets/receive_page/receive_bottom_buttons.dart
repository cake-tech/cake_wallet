import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ReceiveBottomButtons extends StatelessWidget {
  final bool largeQrMode;
  final VoidCallback onCopyButtonPressed;
  final VoidCallback onAmountButtonPressed;
  final VoidCallback onLabelButtonPressed;
  final VoidCallback onAccountsButtonPressed;

  const ReceiveBottomButtons({super.key, required this.largeQrMode, required this.onCopyButtonPressed, required this.onAccountsButtonPressed, required this.onAmountButtonPressed, required this.onLabelButtonPressed});

  @override
  Widget build(BuildContext context) {
    final double targetHeight = largeQrMode ? 0 : 150;
    final double targetOpacity = largeQrMode ? 0 : 1;

    return ClipRect(
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        heightFactor: largeQrMode ? 0 : 1,
        alignment: Alignment.bottomCenter,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: targetOpacity,
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              ModernButton.svg(
                size: 60,
                iconSize: 32,
                svgPath: "assets/new-ui/copy.svg",
                onPressed: onCopyButtonPressed,
                label: "Copy",
                iconColor: Theme.of(context).colorScheme.surfaceContainer,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              ModernButton.svg(
                size: 60,
                iconSize: 32,
                svgPath: "assets/new-ui/set-amount.svg",
                onPressed: onAmountButtonPressed,
                label: "Set Amount"
              ),
              ModernButton.svg(
                size: 60,
                iconSize: 32,
                svgPath: "assets/new-ui/add-label.svg",
                onPressed: onCopyButtonPressed,
                label: "Label"
              ),
              ModernButton.svg(
                size: 60,
                iconSize: 32,
                svgPath: "assets/new-ui/addr-book.svg",
                onPressed: onAccountsButtonPressed,
                label: "Addresses"
              ),
            ],),
          ),
        ),
      ),
    );
  }
}
