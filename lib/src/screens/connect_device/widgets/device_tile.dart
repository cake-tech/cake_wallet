import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:flutter/material.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

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
  final ConnectionType? connectionType;

  String? get connectionTypeIcon {
    switch (connectionType) {
      case ConnectionType.ble:
        return 'assets/images/bluetooth.png';
      case ConnectionType.usb:
        return 'assets/images/usb.png';
      case null:
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
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (leading != null)
              Image.asset(
                leading!,
                height: 30,
                color: Theme.of(context).extension<OptionTileTheme>()!.titleColor,
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).extension<OptionTileTheme>()!.titleColor,
                  ),
                ),
              ),
            ),
            if (connectionTypeIcon != null)
              Center(
                child: Image.asset(
                  connectionTypeIcon!,
                  height: 25,
                  color: Theme.of(context).extension<OptionTileTheme>()!.titleColor,
                ),
              )
          ],
        ),
      ),
    );
  }
}
