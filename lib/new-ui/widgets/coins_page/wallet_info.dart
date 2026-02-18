import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletInfo extends StatelessWidget {
  const WalletInfo(
      {super.key,
      required this.lightningMode,
      required this.name,
      required this.hardwareWalletType,
      required this.onCustomizeButtonTap});

  final bool lightningMode;
  final String name;
  final HardwareWalletType? hardwareWalletType;
  final VoidCallback onCustomizeButtonTap;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  child: SvgPicture.asset(
                    hardwareWalletIcon!,
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface),
        ),
        SizedBox(width: 8),
        ModernButton.svg(
          size: 24,
          onPressed: onCustomizeButtonTap,
          svgPath: "assets/new-ui/3dots.svg",
        )
      ],
    );
  }

  String? get hardwareWalletIcon {
    switch (hardwareWalletType) {
      case null:
        return null;
      case HardwareWalletType.bitbox:
        return "assets/images/hardware_wallet/device_bitbox.svg";
      case HardwareWalletType.ledger:
        return "assets/images/hardware_wallet/device_ledger_nano_x.svg";
      case HardwareWalletType.trezor:
        return "assets/images/hardware_wallet/device_trezor_safe_5.svg";
      case HardwareWalletType.cupcake:
        return "assets/images/cupcake.svg";
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
        return "assets/images/hardware_wallet/device_qr.svg";
    }
  }
}
