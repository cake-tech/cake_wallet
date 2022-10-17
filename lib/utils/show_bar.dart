import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

Future<T?> showBar<T>(
  BuildContext context,
  String messageText, {
  bool isDark = false,
  Duration duration = const Duration(seconds: 1),
  bool isDismissible = true,
  String? titleText,
}) async {
  return showFlash(
    context: context,
    duration: duration,
    builder: (context, controller) => Flash<void>(
      controller: controller,
      borderRadius: const BorderRadius.all(Radius.circular(35)),
      barrierDismissible: false,
      enableVerticalDrag: false,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.09),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
      behavior: FlashBehavior.floating,
      position: FlashPosition.top,
      margin: const EdgeInsets.all(50),
      child: FlashBar(
        title: titleText != null
            ? Text(
                titleText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
              )
            : null,
        content: Text(
          messageText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}

Flash<void> createBar<T>(
  String text,
  FlashController<void> controller,
) {
  return Flash<void>(
    controller: controller,
    borderRadius: const BorderRadius.all(Radius.circular(35)),
    barrierDismissible: false,
    enableVerticalDrag: false,
    boxShadows: [
      BoxShadow(
        color: Colors.black.withOpacity(0.09),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    behavior: FlashBehavior.floating,
    position: FlashPosition.top,
    margin: EdgeInsets.all(50),
    child: FlashBar(
      content: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    ),
  );
}

Future<T?> showToast<T>(
  BuildContext context, {
  required FlashBuilder<T> builder,
  bool isDark = false,
  Duration duration = const Duration(seconds: 1),
  bool isDismissible = true,
  Duration transitionDuration = const Duration(milliseconds: 500),
  bool persistent = true,
  WillPopCallback? onWillPop,
}) {
  return showFlash<T>(
    context: context,
    builder: builder,
    duration: duration,
    transitionDuration: transitionDuration,
    persistent: persistent,
    onWillPop: onWillPop,
  );
}
