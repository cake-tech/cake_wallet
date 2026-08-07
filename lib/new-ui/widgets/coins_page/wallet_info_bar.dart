import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/wallet_info.dart";
import "package:flutter/material.dart";

class WalletInfoBar extends StatelessWidget {
  const WalletInfoBar({required this.name, required this.hardwareWalletType, super.key});

  final String name;
  final HardwareWalletType? hardwareWalletType;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, animation) => SizeTransition(
            axis: Axis.horizontal,
            sizeFactor: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: hardwareWalletType?.iconPath == null
              ? const SizedBox.shrink(key: ValueKey("empty"))
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CakeImageWidget(
                    imageUrl: hardwareWalletType?.iconPath,
                    key: const ValueKey("hardware_wallet_icon"),
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
                ),

        ),
        Text(
          name,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      ]);
}
