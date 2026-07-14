import 'package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    required this.onPressed,
    required this.title,
    this.leading,
    this.connectionType,
  });

  final VoidCallback onPressed;
  final String title;
  final String? leading;
  final HardwareWalletConnectionType? connectionType;

  String? get connectionTypeIcon {
    switch (connectionType) {
      case HardwareWalletConnectionType.ble:
        return 'assets/images/bluetooth.png';
      case HardwareWalletConnectionType.usb:
        return 'assets/images/usb.png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CakeImageWidget(
              height: 30,
              imageUrl: leading,
              colorFilter:
                  ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
            if (connectionTypeIcon != null)
              Center(
                child: Image.asset(
                  connectionTypeIcon!,
                  height: 25,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              )
          ],
        ),
      ),
    );
  }
}
