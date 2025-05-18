import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class SyncIndicatorIcon extends StatelessWidget {
  SyncIndicatorIcon(
      {this.boolMode = true,
      this.isSynced = false,
      this.value = waiting,
      this.size = 6.0});

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
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.error;
    } else {
      switch (value.toLowerCase()) {
        case waiting:
          indicatorColor = Theme.of(context).colorScheme.error;
          break;
        case actionRequired:
          indicatorColor = Theme.of(context).colorScheme.secondaryContainer;
          break;
        case created:
          indicatorColor = Theme.of(context).colorScheme.primary;
          break;
        case fetching:
          indicatorColor = Theme.of(context).colorScheme.error;
          break;
        case finished:
        case success:
        case complete:
          indicatorColor = Theme.of(context).colorScheme.primary;
          break;
        default:
          indicatorColor = Theme.of(context).colorScheme.error;
      }
    }
    return Container(
        height: size,
        width: size,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: indicatorColor));
  }
}
