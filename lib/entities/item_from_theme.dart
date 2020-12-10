import 'package:cake_wallet/themes.dart';
import 'package:flutter/material.dart';

dynamic itemFromTheme({
  @required Themes currentTheme,
  @required Map<Themes, dynamic> items}) {
  switch (currentTheme) {
    case Themes.light:
      return items[Themes.light];
    case Themes.bright:
      return items[Themes.bright];
    case Themes.dark:
      return items[Themes.dark];
    default:
      return items[Themes.light];
  }
}