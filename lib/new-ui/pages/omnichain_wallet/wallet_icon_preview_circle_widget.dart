import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/widgets/image_widgets/wallet_icon_widget.dart";
import "package:flutter/material.dart";

class WalletIconPreviewCircle extends StatelessWidget {
  const WalletIconPreviewCircle({
    required this.icon,
    super.key,
    this.background,
    this.size = 100,
  });

  final WalletIcon? icon;

  final Gradient? background;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: background,
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
        ),
        child: WalletIconContent(icon: icon, size: size * 0.56),
      );
}
