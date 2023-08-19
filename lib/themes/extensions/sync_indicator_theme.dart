import 'package:flutter/material.dart';

class SyncIndicatorTheme extends ThemeExtension<SyncIndicatorTheme> {
  final Color textColor;
  final Color syncedBackgroundColor;
  final Color notSyncedIconColor;
  final Color notSyncedBackgroundColor;

  SyncIndicatorTheme(
      {required this.textColor,
      required this.syncedBackgroundColor,
      required this.notSyncedIconColor,
      required this.notSyncedBackgroundColor});

  @override
  SyncIndicatorTheme copyWith({
    Color? textColor,
    Color? syncedBackgroundColor,
    Color? notSyncedIconColor,
    Color? notSyncedBackgroundColor,
  }) =>
      SyncIndicatorTheme(
          textColor: textColor ?? this.textColor,
          syncedBackgroundColor:
              syncedBackgroundColor ?? this.syncedBackgroundColor,
          notSyncedIconColor: notSyncedIconColor ?? this.notSyncedIconColor,
          notSyncedBackgroundColor:
              notSyncedBackgroundColor ?? this.notSyncedBackgroundColor);

  @override
  SyncIndicatorTheme lerp(ThemeExtension<SyncIndicatorTheme>? other, double t) {
    if (other is! SyncIndicatorTheme) {
      return this;
    }

    return SyncIndicatorTheme(
        textColor: Color.lerp(textColor, other.textColor, t) ?? textColor,
        syncedBackgroundColor:
            Color.lerp(syncedBackgroundColor, other.syncedBackgroundColor, t) ??
                syncedBackgroundColor,
        notSyncedIconColor:
            Color.lerp(notSyncedIconColor, other.notSyncedIconColor, t) ??
                notSyncedIconColor,
        notSyncedBackgroundColor: Color.lerp(
                notSyncedBackgroundColor, other.notSyncedBackgroundColor, t) ??
            notSyncedBackgroundColor);
  }
}
