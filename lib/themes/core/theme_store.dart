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

  @action
  Future<void> setThemeMode(ThemeMode mode, {bool shouldRefreshTheme = true}) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await sharedPreferences.setString(PreferencesKey.themeMode, mode.toString());

    if (mode == ThemeMode.system && shouldRefreshTheme) {
      setTheme(getThemeFromSystem());
    }
  }

  /// Loads the saved theme preferences
  Future<void> loadThemePreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();

    await _loadThemeMode();
    await _loadAndSetTheme();

    _setupThemeReaction();
  }

  /// Loads the saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    final savedThemeMode = sharedPreferences.getString(PreferencesKey.themeMode);
    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedThemeMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  /// Loads and sets the appropriate theme based on platform and installation status
  Future<void> _loadAndSetTheme() async {
    final bool isNewInstall = sharedPreferences.getBool(PreferencesKey.isNewInstall) ?? true;

    bool shouldUseMobileTheme =
        responsiveLayoutUtil.shouldRenderMobileUI && DeviceInfo.instance.isMobile;

    if (shouldUseMobileTheme) {
      await _handleMobileTheme(isNewInstall);
    } else {
      await _handleNonMobileTheme();
    }
  }

  /// Handles theme loading for non-mobile platforms
  Future<void> _handleNonMobileTheme() async {
    await setTheme(ThemeList.darkTheme);
    await setThemeMode(ThemeMode.dark);
  }

  /// Handles theme loading for mobile platforms
  Future<void> _handleMobileTheme(bool isNewInstall) async {
    if (isNewInstall) {
      await _setSystemTheme();
    } else {
      await _loadSavedTheme();
    }
  }

  /// Sets the theme based on system brightness
  Future<void> _setSystemTheme() async {
    await setTheme(getThemeFromSystem());
    await setThemeMode(ThemeMode.system);
  }

  /// Loads the saved theme from SharedPreferences
  Future<void> _loadSavedTheme() async {
    final savedTheme = sharedPreferences.getInt(PreferencesKey.currentTheme);
    if (savedTheme != null) {
      try {
        final theme = ThemeList.deserialize(raw: savedTheme);
        await setTheme(theme);
        await setThemeMode(ThemeMode.system, shouldRefreshTheme: false);
      } catch (e) {
        await _setSystemTheme();
      }
    }
  }

  /// Sets up a reaction to save theme changes to SharedPreferences
  void _setupThemeReaction() {
    reaction(
      (_) => currentTheme,
      (MaterialThemeBase theme) => sharedPreferences.setInt(PreferencesKey.currentTheme, theme.raw),
    );
  }

  MaterialThemeBase getThemeFromSystem() {
    final systemBrightness = WidgetsBinding.instance.window.platformBrightness;
    return systemBrightness == Brightness.dark ? ThemeList.darkTheme : ThemeList.lightTheme;
  }
}
