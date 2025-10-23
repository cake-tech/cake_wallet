import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SyncIndicatorIcon extends StatelessWidget {
  SyncIndicatorIcon(
      {this.boolMode = true,
      this.isSynced = false,
      this.value = waiting,
      this.size = 6.0,
      this.showTorIcon = false});

  final bool boolMode;
  final bool isSynced;
  final String value;
  final double size;
  final bool showTorIcon;

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
      indicatorColor = isSynced ? CustomThemeColors.syncGreen : CustomThemeColors.syncYellow;
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
      decoration: showTorIcon
          ? null
          : BoxDecoration(
              shape: BoxShape.circle,
              color: indicatorColor,
            ),
      child: showTorIcon
          ? SvgPicture.asset(
              "assets/images/tor.svg",
              color: indicatorColor,
            )
          : null,
    );
  }
}
