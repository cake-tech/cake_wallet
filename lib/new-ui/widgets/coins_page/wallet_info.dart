import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletInfo extends StatelessWidget {
  const WalletInfo(
      {super.key,
      required this.lightningMode,
      required this.name,
      required this.usesHardwareWallet,
      required this.onCustomizeButtonTap});

  final bool lightningMode;
  final String name;
  final bool usesHardwareWallet;
  final VoidCallback onCustomizeButtonTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        AnimatedSwitcher(
          duration: Duration(milliseconds: 150),
          transitionBuilder: (child, animation) {
            return SizeTransition(
              axis: Axis.horizontal,
              sizeFactor: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: !usesHardwareWallet
              ? SizedBox.shrink(key: ValueKey("empty"))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                  child: SvgPicture.asset(
                    "assets/new-ui/wallet-trezor.svg",
                    key: ValueKey("wallet"),
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
        ),
        Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        SizedBox(width: 8),
        ModernButton.svg(
          size: 24,
          onPressed: onCustomizeButtonTap,
          svgPath: "assets/new-ui/3dots.svg",
        )
      ],
    );
  }
}
