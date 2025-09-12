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

  @computed
  bool get hasCustomTheme => sharedPreferences.getInt(PreferencesKey.currentTheme) != null;

  @computed
  MaterialThemeBase? get savedCustomTheme {
    final raw = sharedPreferences.getInt(PreferencesKey.currentTheme);
    return raw != null ? ThemeList.deserialize(raw: raw) : null;
  }

  late SharedPreferences sharedPreferences;

  @action
  Future<void> setTheme(MaterialThemeBase theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    await sharedPreferences.setInt(PreferencesKey.currentTheme, theme.raw);
  }

  @action
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _saveThemeModeToPrefs(mode);

    if (!hasCustomTheme) {
      if (mode == ThemeMode.system) {
        await setTheme(getThemeFromSystem());
      }
      return;
    }

    final savedTheme = savedCustomTheme;
    if (savedTheme == null) return;

    if (_isThemeCompatibleWithMode(savedTheme, mode)) {
      await setTheme(savedTheme);
    }
  }

  Future<void> _saveThemeModeToPrefs(ThemeMode mode) async {
    await sharedPreferences.setString(PreferencesKey.themeMode, mode.toString());
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
      await _setSystemTheme(isNewInstall: isNewInstall);
    } else {
      await loadSavedTheme();
    }
  }

  /// Loads the saved theme from SharedPreferences
  Future<void> loadSavedTheme({bool isFromBackup = false}) async {
    try {
      final theme = savedCustomTheme;

      if (!hasCustomTheme || theme == null) {
        await _setSystemTheme();
        return;
      }

      if (_currentTheme != theme) {
        await setTheme(theme);
      }

      final newThemeMode = _getThemeModeOnStartUp(theme, isFromBackup);

      if (newThemeMode == ThemeMode.system) {
        await _setSystemTheme();
        return;
      }

      if (_themeMode != newThemeMode) {
        await setThemeMode(newThemeMode);
      }
    } catch (e) {
      await _setSystemTheme();
    }
  }

  Future<void> _setSystemTheme({bool isNewInstall = false}) async {
    if (!isNewInstall && hasCustomTheme) return;

    final systemTheme = getThemeFromSystem();

    if (_currentTheme != systemTheme) {
      await setTheme(systemTheme);
    }

    if (isNewInstall) {
      await _saveThemeModeToPrefs(ThemeMode.system);
      if (_themeMode != ThemeMode.system) {
        await setThemeMode(ThemeMode.system);
      }
    }
  }

  ThemeMode _getThemeModeOnStartUp(MaterialThemeBase theme, bool isFromBackup) {
    if (isFromBackup || _themeMode != ThemeMode.system) {
      return theme.isDark ? ThemeMode.dark : ThemeMode.light;
    }

    return ThemeMode.system;
  }

  void _setupThemeReaction() {
    reaction(
      (_) => currentTheme,
      (MaterialThemeBase theme) => sharedPreferences.setInt(PreferencesKey.currentTheme, theme.raw),
    );
  }

  MaterialThemeBase getThemeFromSystem() {
    final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return systemBrightness == Brightness.dark ? ThemeList.darkTheme : ThemeList.lightTheme;
  }

  /// Checks if a theme is compatible with a theme mode
  bool _isThemeCompatibleWithMode(MaterialThemeBase theme, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return !theme.isDark;
      case ThemeMode.dark:
        return theme.isDark;
      case ThemeMode.system:
        return true; // All themes are compatible with system mode
    }
  }
}
