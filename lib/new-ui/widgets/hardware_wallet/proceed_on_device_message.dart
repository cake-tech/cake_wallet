import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/hardware/hardware_signing_stage.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';

class HardwareWalletProceedOnDeviceMessage extends StatelessWidget {
  const HardwareWalletProceedOnDeviceMessage({
    super.key,
    required this.hardwareWalletType,
    this.stage,
  });

  final HardwareWalletType hardwareWalletType;

  /// Where the signing is, for wallets that report it. Without it the message
  /// is the plain "proceed on your device".
  final HardwareSigningStage? stage;

  /// What the user is waiting on right now.
  static String textFor(BuildContext context, HardwareSigningStage? stage) {
    final s = S.of(context);
    return switch (stage) {
      HardwareSigningStage.preparing => "${s.preparing_transaction}...",
      HardwareSigningStage.sendingToDevice => "${s.sending_to_device}...",
      HardwareSigningStage.signing => "${s.signing_transaction}...",
      HardwareSigningStage.finalizing => "${s.finalizing_transaction}...",
      HardwareSigningStage.awaitingDevice || null => s.proceed_on_device,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(spacing: 8, children: [
          if (hardwareWalletIcon != null)
            CakeImageWidget(
              imageUrl: hardwareWalletIcon!,
              width: 36,
              height: 36,
              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
            ),
          Text(
            textFor(context, stage),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          )
        ]),
      ),
    );
  }

  String? get hardwareWalletIcon {
    switch (hardwareWalletType) {
      case HardwareWalletType.bitbox:
        return "assets/new-ui/hardware_wallets/device_bitbox.svg";
      case HardwareWalletType.ledger:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg";
      case HardwareWalletType.trezor:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_7.svg";
      case HardwareWalletType.cupcake:
        return "assets/images/cupcake.svg";
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
        return "assets/images/hardware_wallet/device_qr.svg";
    }
  }
}
