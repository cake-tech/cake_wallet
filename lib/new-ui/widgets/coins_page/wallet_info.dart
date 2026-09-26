import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';

class WalletInfoBar extends StatelessWidget {
  const WalletInfoBar({
    required this.name,
    required this.hardwareWalletType,
    super.key,
  });

  final String name;
  final HardwareWalletType? hardwareWalletType;

  // Roughly the cap height of titleMedium, so the icon reads as part of the
  // name rather than towering over it.
  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel =
        hardwareWalletType == null ? name : "$name, ${S.of(context).hardware_wallet}";

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        // The icon is laid out inline with the text so the font metrics, not
        // the line box, decide its vertical position: it is centred on the
        // middle of the glyphs, which is what the eye compares it against.
        child: Text.rich(
          key: const ValueKey("home_page_wallet_name_text_key"),
          TextSpan(
            children: [
              if (hardwareWalletIcon != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    // The text "middle" is the em-box middle, a touch above the
                    // cap centre; the top padding nudges the icon down onto it.
                    padding: const EdgeInsets.only(right: 6, top: 3),
                    child: CakeImageWidget(
                      imageUrl: hardwareWalletIcon!,
                      key: const ValueKey("hardware_wallet_icon"),
                      width: _iconSize,
                      height: _iconSize,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              TextSpan(text: name),
            ],
          ),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  String? get hardwareWalletIcon {
    switch (hardwareWalletType) {
      case null:
        return null;
      case HardwareWalletType.bitbox:
        return "assets/new-ui/hardware_wallets/device_bitbox.svg";
      case HardwareWalletType.ledger:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg";
      case HardwareWalletType.trezor:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_5.svg";
      case HardwareWalletType.cupcake:
        return "assets/images/cupcake.svg";
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
        return "assets/images/hardware_wallet/device_qr.svg";
    }
  }
}
