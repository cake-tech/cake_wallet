import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletInfoBar extends StatelessWidget {
  const WalletInfoBar({required this.name, required this.hardwareWalletType, super.key});

  final String name;
  final HardwareWalletType? hardwareWalletType;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
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
                    padding: const EdgeInsets.only(right: 8),
                    child: CakeImageWidget(
                      imageUrl: hardwareWalletIcon!,
                      key: const ValueKey("hardware_wallet_icon"),
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
            // if (hasCustomize) ...[
            //   SizedBox(width: 8),
            //   ModernButton.svg(
            //     size: 24,
            //     onPressed: () {
            //       if (hasCustomize) {
            //         onCustomizeButtonTap();
            //         HapticFeedback.mediumImpact();
            //       }
            //     },
            //     svgPath: "assets/new-ui/icon-accounts.svg",
            //     semanticLabel: S.of(context).wallet_accounts,
            //   )
          ),
        ],
      );

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
