import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class ReceiveAddressTypeDisplay extends StatelessWidget {
  const ReceiveAddressTypeDisplay({
    required this.selected,
    required this.walletType,
    required this.largeQrMode,
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final ReceivePageOption selected;
  final WalletType walletType;
  final bool largeQrMode;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final walletTypeString = walletTypeToString(walletType);
    var text = selected.value;

    if (selected == ReceivePageOption.mainnet) {
      text = largeQrMode
          ? "$walletTypeString ${S.of(context).address}"
          : "$walletTypeString (${S.of(context).mainnet})";
    } else if (largeQrMode && selected.addAddressWord) {
      text = "$text ${S.of(context).address}";
    }

    var iconPath = selected.iconPath;
    if (iconPath != null && walletTypeString == "Litecoin" && text.contains("Standard")) {
      iconPath = "assets/new-ui/address-type-picker-icons/litecoin.svg";
    }

    // The row and the chevron button trigger the same picker, so only the
    // row is exposed and the chevron is treated as decoration.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: S.of(context).address_type,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            key: ValueKey("$text$largeQrMode"),
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              if (iconPath != null)
                ExcludeSemantics(
                  child: CakeImageWidget(
                    imageUrl: iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              Text(
                text,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
              ),
              if (!largeQrMode)
                ExcludeSemantics(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(999999),
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CupertinoActivityIndicator(radius: 7),
                          )
                        : IconButton(
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
