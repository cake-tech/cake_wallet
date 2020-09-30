import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<T> showBar<T>(BuildContext context, String text,
    {bool isDark = false, Duration duration = const Duration(seconds: 1), bool isDismissible = true}) {
  final bar = Flushbar<T>(
      boxShadows: [
        BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 8,
            offset: Offset(0, 2))
      ],
      backgroundColor: isDark ? Colors.black : Colors.white,
      borderRadius: 35,
      margin: EdgeInsets.all(50),
      messageText: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      duration: duration,
      isDismissible: isDismissible,
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING);

  return bar.show(context);
}

Flushbar<T> createBar<T>(String text,
    {bool isDark = false, Duration duration = const Duration(seconds: 1), bool isDismissible = true}) {
  return Flushbar<T>(
      boxShadows: [
        BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 8,
            offset: Offset(0, 2))
      ],
      backgroundColor: isDark ? Colors.black : Colors.white,
      borderRadius: 35,
      margin: EdgeInsets.all(50),
      messageText: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      duration: duration,
      isDismissible: isDismissible,
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING);
}
