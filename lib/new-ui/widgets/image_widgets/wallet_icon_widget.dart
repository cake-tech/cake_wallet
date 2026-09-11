import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_preset_icons.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/omnichain_wallet_emoji_picker_sheet.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

class WalletIconAvatar extends StatelessWidget {
  const WalletIconAvatar({
    required this.icon,
    this.size = 100,
    this.contentSize = 48,
  });

  final WalletIcon? icon;
  final double size;
  final double contentSize;

  @override
  Widget build(BuildContext context) {
    final backgroundEnabled = icon?.backgroundEnabled ?? true;
    final colors = OmniChainWalletEmojiPickerSheet.backgroundColors(context);
    final colorIndex = (icon?.colorIndex ?? 0).clamp(0, colors.length - 1);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: backgroundEnabled ? colors[colorIndex] : null,
        color: backgroundEnabled ? null : Colors.transparent,
      ),
      alignment: Alignment.center,
      child: _WalletIconContent(icon: icon, size: contentSize),
    );
  }
}

class _WalletIconContent extends StatelessWidget {
  const _WalletIconContent({required this.icon, required this.size});

  final WalletIcon? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) return const SizedBox.shrink();

    switch (icon.type) {
      case WalletIconType.emoji:
        if (icon.value.isEmpty) return const SizedBox.shrink();
        return CakeImageWidget(imageUrl: icon.value, width: size, height: size);
      case WalletIconType.image:
        return CakeImageWidget(imageUrl: icon.value, width: size, height: size);
      case WalletIconType.preset:
        final assetPath = WalletPresetIcons.assetPathFor(icon.value) ?? icon.value;
        return CakeImageWidget(imageUrl: assetPath, width: size, height: size);
      case WalletIconType.crypto:
        final walletType = WalletType.values.asNameMap()[icon.value];
        final assetPath =
            walletType != null ? getCryptoCurrencyIconForWalletListItem(walletType) : icon.value;
        return CakeImageWidget(imageUrl: assetPath, width: size, height: size);
    }
  }
}