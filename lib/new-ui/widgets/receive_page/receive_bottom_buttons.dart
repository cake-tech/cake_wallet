import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ReceiveBottomButtons extends StatelessWidget {
  final bool largeQrMode;
  final VoidCallback onCopyButtonPressed;
  final VoidCallback onAccountsButtonPressed;

  const ReceiveBottomButtons({super.key, required this.largeQrMode, required this.onCopyButtonPressed, required this.onAccountsButtonPressed});

  @override
  Widget build(BuildContext context) {
    final double targetHeight = largeQrMode ? 0 : 150;
    final double targetOpacity = largeQrMode ? 0 : 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: targetHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: targetOpacity,
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            spacing: 15.0,
            children: [
              NewPrimaryButton(
                onPressed: onAccountsButtonPressed,
                image: SvgPicture.asset(
                  "assets/new-ui/addr-book.svg",
                  colorFilter:
                      ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                ),
                text: "Accounts & Addresses",
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.primary,
              ),
              NewPrimaryButton(
                onPressed: onCopyButtonPressed,
                image: SvgPicture.asset("assets/new-ui/copy-icon.svg",
                    colorFilter:
                        ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn)),
                text: "Copy Address",
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
