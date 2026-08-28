import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/widgets/image_widgets/wallet_icon_widget.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/wallet_info.dart";
import "package:flutter/material.dart";

class WalletInfoBar extends StatelessWidget {
  const WalletInfoBar({required this.name, required this.walletIcon, this.hardwareWalletType, super.key});

  final String name;
  final WalletIcon? walletIcon;
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
        if (walletIcon != null) ...[
          const SizedBox(width: 8),
          WalletIconAvatar(icon: walletIcon, size: 24, contentSize: 24),
        ],
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],);
}