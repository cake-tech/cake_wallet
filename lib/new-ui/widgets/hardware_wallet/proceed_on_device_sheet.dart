import 'package:cake_wallet/new-ui/widgets/hardware_wallet/proceed_on_device_message.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';

class HardwareWalletProceedOnDeviceSheet extends StatelessWidget {
  const HardwareWalletProceedOnDeviceSheet({super.key, required this.hardwareWalletType});

  final HardwareWalletType hardwareWalletType;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        bottom: false,
        minimum: EdgeInsets.only(top: 64),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: AnimatedSize(
                  alignment: Alignment.bottomCenter,
                  duration: Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 150),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Container(
                      child: HardwareWalletProceedOnDeviceMessage(
                          hardwareWalletType: hardwareWalletType),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
