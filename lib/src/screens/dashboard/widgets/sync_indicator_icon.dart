import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class SyncIndicatorIcon extends StatelessWidget {
  SyncIndicatorIcon(
      {this.boolMode = true, this.isSynced = false, this.value = waiting, this.size = 6.0});

  final bool boolMode;
  final bool isSynced;
  final String value;
  final double size;

  static const String waiting = 'waiting';
  static const String actionRequired = 'action required';
  static const String created = 'created';
  static const String fetching = 'fetching';
  static const String finished = 'finished';
  static const String success = 'success';
  static const String complete = 'complete';

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;

    if (boolMode) {
      indicatorColor = isSynced
          ? CustomThemeColors.syncGreen
          : CustomThemeColors.syncYellow;
    } else {
      switch (value.toLowerCase()) {
        case actionRequired:
          indicatorColor = Theme.of(context).colorScheme.surfaceContainer;
          break;
        case created:
        case finished:
        case success:
        case complete:
          indicatorColor = CustomThemeColors.syncGreen;
          break;
        case waiting:
        case fetching:
        default:
          indicatorColor = Theme.of(context).colorScheme.errorContainer;
      }
    }
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: indicatorColor,
      ),
    );
  }
}
