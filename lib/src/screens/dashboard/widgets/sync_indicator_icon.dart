import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class SyncIndicatorIcon extends StatelessWidget {
  SyncIndicatorIcon(
      {this.boolMode = true,
      this.isSynced = false,
      this.value = waiting,
      this.size = 4.0});

  final bool boolMode;
  final bool isSynced;
  final String value;
  final double size;

  static const String waiting = 'waiting';
  static const String actionRequired = 'action required';
  static const String created = 'created';
  static const String fetching = 'fetching';
  static const String finished = 'finished';

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;

    if (boolMode) {
      indicatorColor = isSynced
          ? PaletteDark.brightGreen
          : Theme.of(context).extension<SyncIndicatorTheme>()!.notSyncedIconColor;
    } else {
      switch (value.toLowerCase()) {
        case waiting:
          indicatorColor = Colors.red;
          break;
        case actionRequired:
          indicatorColor =
              Theme.of(context).extension<ReceivePageTheme>()!.currentTileBackgroundColor;
          break;
        case created:
          indicatorColor = PaletteDark.brightGreen;
          break;
        case fetching:
          indicatorColor = Colors.red;
          break;
        case finished:
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
