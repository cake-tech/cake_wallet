import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/themes/utils/theme_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'material_base_theme.dart';

part 'theme_store.g.dart';

/// MobX store for managing theme state
class ThemeStore = ThemeStoreBase with _$ThemeStore;

abstract class ThemeStoreBase with Store {
  ThemeStoreBase() {
    loadThemePreferences();
  }

  @observable
  MaterialThemeBase _currentTheme = ThemeList.lightTheme;

  @observable
  ThemeMode _themeMode = ThemeMode.system;

  @computed
  MaterialThemeBase get currentTheme => _currentTheme;

  @computed
  ThemeMode get themeMode => _themeMode;

  @computed
  bool get isDarkMode => _currentTheme.isDark;

  late SharedPreferences sharedPreferences;

  @action
  Future<void> setTheme(MaterialThemeBase theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    await sharedPreferences.setInt(PreferencesKey.currentTheme, theme.raw);
  }

  /// Loads the saved theme preferences
  Future<void> loadThemePreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();

    final bool isNewInstall = sharedPreferences.getBool(PreferencesKey.isNewInstall) ?? true;
    MaterialThemeBase? initialTheme;

    if (responsiveLayoutUtil.shouldRenderMobileUI && DeviceInfo.instance.isMobile) {
      initialTheme = null;
      if (isNewInstall) {
        setTheme(_getThemeFromSystem());
      } else {
        final savedTheme = sharedPreferences.getInt(PreferencesKey.currentTheme);
        if (savedTheme != null) {
          try {
            final theme = ThemeList.deserialize(raw: savedTheme);
            _currentTheme = theme;
          } catch (e) {
            final _fallbackTheme = _getThemeFromSystem();
            _currentTheme = _fallbackTheme;
          }
        }
      }
    } else {
      // Enforce darkTheme on platforms other than mobile
      initialTheme = ThemeList.darkTheme;
      setTheme(initialTheme);
    }

    reaction(
      (_) => currentTheme,
      (MaterialThemeBase theme) => sharedPreferences.setInt(PreferencesKey.currentTheme, theme.raw),
    );
  }

  MaterialThemeBase _getThemeFromSystem() {
    final systemBrightness = WidgetsBinding.instance.window.platformBrightness;
    return systemBrightness == Brightness.dark ? ThemeList.darkTheme : ThemeList.lightTheme;
  }
}
