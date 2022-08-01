import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class SyncIndicatorIcon extends StatelessWidget {
  SyncIndicatorIcon(
      {this.boolMode = true,
      this.isSynced = false,
      this.value = 'Waiting',
      this.size = 4.0});

  final bool boolMode;
  final bool isSynced;
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;

    if (boolMode) {
      indicatorColor = isSynced
          ? PaletteDark.brightGreen
          : Theme.of(context).textTheme.caption.color;
    } else {
      switch (value) {
        case 'Waiting':
          indicatorColor = Colors.red;
          break;
        case 'Action required':
          indicatorColor = Theme.of(context).textTheme.display3.decorationColor;
          break;
        case 'Created':
          indicatorColor = PaletteDark.brightGreen;
          break;
        case 'Fetching':
          indicatorColor = Colors.red;
          break;
        case 'Finished':
          indicatorColor = PaletteDark.brightGreen;
          break;
        default:
          indicatorColor = Colors.red;
      }
    }
    return Container(
        height: size,
        width: size,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: indicatorColor));
  }
}
