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

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel =
        hardwareWalletType == null ? name : "$name, ${S.of(context).hardware_wallet}";

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Row(
          // Align the icon to the text baseline rather than to the centre of
          // the text's line box: the glyphs sit low in that box, so a centred
          // icon (especially the full-height Trezor glyph) floats above them.
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: hardwareWalletIcon == null
                  ? const SizedBox.shrink(key: ValueKey("empty"))
                  : Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Baseline(
                        // Icon bottom lands 1pt below the text baseline, so
                        // the glyph is centred on the cap height.
                        baseline: _iconSize - 1,
                        baselineType: TextBaseline.alphabetic,
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
            ),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
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
