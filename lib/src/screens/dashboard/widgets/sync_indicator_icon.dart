import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class SyncIndicatorIcon extends StatelessWidget {
  SyncIndicatorIcon({this.isSynced});

  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 4,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSynced
              ? PaletteDark.brightGreen
              : Theme.of(context).textTheme.caption.color),
    );
  }
}
