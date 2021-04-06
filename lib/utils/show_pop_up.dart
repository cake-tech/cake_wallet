import 'package:flutter/material.dart';

Future<T> showPopUp<T>({
  @required BuildContext context,
  WidgetBuilder builder,
  bool barrierDismissible = true,
  Color barrierColor,
  bool useSafeArea = false,
  bool useRootNavigator = true,
  RouteSettings routeSettings
}) {
  return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings);
}
