import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/sync_status_display_mode.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/theme_classes/black_theme.dart';
import 'package:cake_wallet/themes/utils/theme_list.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:flutter/material.dart';

part 'display_settings_view_model.g.dart';

class DisplaySettingsViewModel = DisplaySettingsViewModelBase with _$DisplaySettingsViewModel;

abstract class DisplaySettingsViewModelBase with Store {
  DisplaySettingsViewModelBase(this._settingsStore, this._themeStore);

  final SettingsStore _settingsStore;
  final ThemeStore _themeStore;

  @computed
  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

  @computed
  String get languageCode => _settingsStore.languageCode;

  @computed
  BalanceDisplayMode get balanceDisplayMode => _settingsStore.balanceDisplayMode;

  @computed
  bool get shouldDisplayBalance => balanceDisplayMode == BalanceDisplayMode.displayableBalance;

  @computed
  bool get shouldShowMarketPlaceInDashboard => _settingsStore.shouldShowMarketPlaceInDashboard;

  @computed
  BitcoinAmountDisplayMode get displayAmountsInSatoshi => _settingsStore.displayAmountsInSatoshi;

  @computed
  MaterialThemeBase get currentTheme => _themeStore.currentTheme;

  @computed
  ThemeMode get themeMode => _themeStore.themeMode;

  @computed
  bool get isBlackThemeOledEnabled => _themeStore.currentTheme is BlackTheme && _themeStore.isOled;

  @computed
  bool get disabledFiatApiMode => _settingsStore.fiatApiMode == FiatApiMode.disabled;

  @computed
  bool get showAddressBookPopup => _settingsStore.showAddressBookPopupEnabled;

  @computed
  SyncStatusDisplayMode get syncStatusDisplayMode => _settingsStore.syncStatusDisplayMode;

  @computed
  String get backgroundImage => _settingsStore.backgroundImage;

  @computed
  List<MaterialThemeBase> get availableThemes {
    List<MaterialThemeBase> themes;
    switch (themeMode) {
      case ThemeMode.light:
        themes = ThemeList.all.where((theme) => theme.brightness == Brightness.light).toList();
        break;
      case ThemeMode.dark:
        themes = ThemeList.all.where((theme) => theme.brightness == Brightness.dark).toList();
        break;
      case ThemeMode.system:
        final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        themes = ThemeList.all.where((theme) => theme.brightness == systemBrightness).toList();
        break;
    }

    List<MaterialThemeBase> groupedThemes = [];
    Set<String> addedThemeFamilies = {};

    for (final theme in themes) {
      if (theme.hasAccentColors) {
        final family = theme.themeFamily!;
        if (!addedThemeFamilies.contains(family)) {
          groupedThemes.add(theme);
          addedThemeFamilies.add(family);
        }
      } else {
        groupedThemes.add(theme);
      }
    }

    return groupedThemes;
  }

  @computed
  List<ThemeAccentColor> get availableAccentColors {
    if (!currentTheme.hasAccentColors) return [];

    if (currentTheme.themeFamily == 'BlackTheme') {
      return BlackThemeAccentColor.values;
    }
    return [];
  }

  @action
  void setBalanceDisplayMode(BalanceDisplayMode value) => _settingsStore.balanceDisplayMode = value;

  @action
  void setDisplayAmountsInSatoshi(BitcoinAmountDisplayMode value) => _settingsStore.displayAmountsInSatoshi = value;

  @action
  void setShouldDisplayBalance(bool value) {
    if (value) {
      _settingsStore.balanceDisplayMode = BalanceDisplayMode.displayableBalance;
    } else {
      _settingsStore.balanceDisplayMode = BalanceDisplayMode.hiddenBalance;
    }
  }

  @action
  void onLanguageSelected(String code) {
    _settingsStore.languageCode = code;
  }

  @action
  Future<void> onThemeSelected(MaterialThemeBase newTheme) async {
    if (newTheme is BlackTheme && _themeStore.isOled) {
      await setTheme(BlackTheme(newTheme.accentColor, isOled: true));
      return;
    }
    await setTheme(newTheme);
  }

  @action
  Future<void> onAccentColorSelected(String accentColorId) async {
    if (!currentTheme.hasAccentColors) return;

    try {
      final newTheme = ThemeList.all.firstWhere(
        (theme) =>
            theme.hasAccentColors &&
            theme.themeFamily == currentTheme.themeFamily &&
            theme.accentColorId == accentColorId,
      );

      if (newTheme != currentTheme) {
        if (newTheme is BlackTheme && _themeStore.isOled) {
          await onThemeSelected(BlackTheme(newTheme.accentColor, isOled: true));
        } else {
          await onThemeSelected(newTheme);
        }
      }
    } catch (_) {}
  }

  @action
  Future<void> setBlackThemeOled(bool value) async {
    if (_themeStore.currentTheme is BlackTheme) {
      await _themeStore.setOledEnabled(value);
    }
  }

  bool isThemeSelected(MaterialThemeBase theme) {
    if (!theme.hasAccentColors) return currentTheme == theme;

    return currentTheme.hasAccentColors && currentTheme.themeFamily == theme.themeFamily;
  }

  bool isAccentColorSelected(String accentColorId) {
    if (!currentTheme.hasAccentColors) return false;

    return currentTheme.accentColorId == accentColorId;
  }

  @action
  Future<void> setTheme(MaterialThemeBase newTheme) async {
    await _themeStore.setTheme(newTheme);
  }

  MaterialThemeBase? getFirstMatchingTheme(ThemeMode mode) {
    List<MaterialThemeBase> themes;
    switch (mode) {
      case ThemeMode.light:
        themes = ThemeList.all.where((theme) => theme.brightness == Brightness.light).toList();
        break;
      case ThemeMode.dark:
        themes = ThemeList.all.where((theme) => theme.brightness == Brightness.dark).toList();
        break;
      case ThemeMode.system:
        final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        themes = ThemeList.all.where((theme) => theme.brightness == systemBrightness).toList();
        break;
    }

    return themes.isNotEmpty ? themes.first : null;
  }

  @action
  Future<void> setThemeMode(ThemeMode value) async {
    await _themeStore.setThemeMode(value);
    // We won't override the saved custom theme when switching to system mode.
    // We'll just let the ThemeStore resolve it based on system brightness and saved theme.
    if (value != ThemeMode.system) {
      final matchingTheme = getFirstMatchingTheme(value);
      if (matchingTheme != null) {
        await setTheme(matchingTheme);
      }
    }
  }

  @action
  void setFiatCurrency(FiatCurrency value) => _settingsStore.fiatCurrency = value;

  @action
  void setShouldShowMarketPlaceInDashbaord(bool value) {
    _settingsStore.shouldShowMarketPlaceInDashboard = value;
  }

  @action
  void setShowAddressBookPopup(bool value) => _settingsStore.showAddressBookPopupEnabled = value;

  @action
  void setSyncStatusDisplayMode(SyncStatusDisplayMode value) =>
      _settingsStore.syncStatusDisplayMode = value;

  @action
  void setBackgroundImage(String path) => _settingsStore.backgroundImage = path;

  String getImageForTheme(MaterialThemeBase theme) {
    switch (theme.title) {
      case 'Dark Theme':
        return 'assets/images/dark.svg';
      case 'Light Theme':
        return 'assets/images/light.svg';
      case 'Black Theme (Cake Primary)':
      case 'Black Theme (BCH Green)':
      case 'Black Theme (Bitcoin Yellow)':
      case 'Black Theme (Monero Orange)':
      case 'Black Theme (Tron Red)':
      case 'Black Theme (Frosting Purple)':
        return 'assets/images/black_accent.svg';
      default:
        return 'assets/images/dark.svg';
    }
  }
}
