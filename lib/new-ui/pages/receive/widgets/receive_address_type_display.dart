import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

class ReceiveAddressTypeDisplay extends StatelessWidget {
  const ReceiveAddressTypeDisplay({
    required this.selected,
    required this.walletType,
    required this.largeQrMode,
    required this.onTap,
    super.key,
  });

  final ReceivePageOption selected;
  final WalletType walletType;
  final bool largeQrMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final walletTypeString = walletTypeToString(walletType);
    var text = selected.value;
    if (largeQrMode && selected.addAddressWord) {
      text += " Address";
    }

    if (text == "mainnet") {
      text = largeQrMode
          ? "$walletTypeString ${S.of(context).address}"
          : "$walletTypeString (Mainnet)";
    }

    var iconPath = selected.iconPath;
    if (iconPath != null && walletTypeString == "Litecoin" && text.contains("Standard")) {
      iconPath = "assets/new-ui/address-type-picker-icons/litecoin.svg";
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        key: ValueKey("$text$largeQrMode"),
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          if (iconPath != null)
            CakeImageWidget(
              imageUrl: iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
          Text(
            text,
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
          ),
          if (!largeQrMode)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(999999),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onTap,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
