import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/themes/utils/theme_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

/// A widget that provides theme management to its descendants.
/// This widget would wrap the [MaterialApp] in the widget tree.
class ThemeProvider extends StatelessWidget {
  final ThemeStore themeStore;
  final MaterialApp Function(BuildContext, ThemeData, ThemeData?, ThemeMode) materialAppBuilder;

  const ThemeProvider({
    Key? key,
    required this.themeStore,
    required this.materialAppBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final theme = themeStore.currentTheme.themeData;
        final darkTheme = ThemeList.darkTheme.themeData;
        final themeMode = themeStore.themeMode;

        return materialAppBuilder(context, theme, darkTheme, themeMode);
      },
    );
  }
}
