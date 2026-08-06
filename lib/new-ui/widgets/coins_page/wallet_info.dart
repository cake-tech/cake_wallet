import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletInfoBar extends StatelessWidget {
  const WalletInfoBar(
      {super.key,
      required this.lightningMode,
      required this.name,
      required this.hardwareWalletType,
      required this.onCustomizeButtonTap,
      required this.hasCustomize});

  final bool lightningMode;
  final String name;
  final HardwareWalletType? hardwareWalletType;
  final bool hasCustomize;
  final VoidCallback onCustomizeButtonTap;

  void _openAccountCustomizer() {
    if (hasCustomize) {
      onCustomizeButtonTap();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The row, the hardware-wallet glyph and the inner accounts button are one
    // control for a screen reader: a single labeled node opening the customizer.
    final semanticsLabel =
        hardwareWalletType == null ? name : "$name, ${S.of(context).hardware_wallet}";

    final row = GestureDetector(
      onTap: _openAccountCustomizer,
      child: Row(
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
            child: hardwareWalletIcon == null
                ? const SizedBox.shrink(key: ValueKey("empty"))
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CakeImageWidget(
                      imageUrl: hardwareWalletIcon!,
                      key: ValueKey("hardware_wallet_icon"),
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
                .titleLarge
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          if (hasCustomize) ...[
            SizedBox(width: 8),
            ModernButton.svg(
              size: 24,
              onPressed: _openAccountCustomizer,
              svgPath: "assets/new-ui/icon-accounts.svg",
              semanticLabel: S.of(context).wallet_accounts,
            )
          ]
        ],
      ),
    );

    if (!hasCustomize) {
      return Semantics(label: semanticsLabel, child: ExcludeSemantics(child: row));
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      hint: S.of(context).wallet_accounts,
      onTap: _openAccountCustomizer,
      child: ExcludeSemantics(child: row),
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
