import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

Future<T?> showBar<T>(BuildContext context, String messageText,
    {bool isDark = false,
    Duration? duration =
        const Duration(seconds: 1), // pass explicitly by null to make the duration indefinite
    bool isDismissible = true,
    String? titleText}) async {
  final bar = Flushbar<T>(
    boxShadows: [
      BoxShadow(
        color: Theme.of(context).colorScheme.surface,
        blurRadius: 8,
        offset: Offset(0, 2),
      )
    ],
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    borderRadius: BorderRadius.circular(35),
    margin: EdgeInsets.all(50),
    titleText: titleText != null
        ? Text(
            titleText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
          )
        : null,
    messageText: Text(
      messageText,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16,
          ),
    ),
    duration: duration,
    isDismissible: isDismissible,
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.FLOATING,
  );

  return bar.show(context);
}

Flushbar<T> createBar<T>(
  String text,
  BuildContext context, {
  bool isDark = false,
  Duration? duration =
      const Duration(seconds: 1), // pass explicitly by null to make the duration indefinite
  bool isDismissible = true,
}) {
  return Flushbar<T>(
    boxShadows: [
      BoxShadow(
        color: Theme.of(context).colorScheme.surface,
        blurRadius: 8,
        offset: Offset(0, 2),
      )
    ],
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    borderRadius: BorderRadius.circular(35),
    margin: EdgeInsets.all(50),
    messageText: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
    ),
    duration: duration,
    isDismissible: isDismissible,
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.FLOATING,
  );
}
