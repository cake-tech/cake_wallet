import 'package:flutter/material.dart';

Future<T?> showPopUp<T>(
    {required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = false,
    bool useRootNavigator = true,
    RouteSettings? routeSettings}) async {
  if (context.mounted) {
    return showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings);
  }

  return null;
}
