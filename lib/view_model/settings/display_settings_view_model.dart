import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
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
  ThemeData get theme => _themeStore.currentTheme.themeData;

  @computed
  ThemeMode get themeMode => _themeStore.themeMode;

  @computed
  bool get disabledFiatApiMode => _settingsStore.fiatApiMode == FiatApiMode.disabled;

  @computed
  bool get showAddressBookPopup => _settingsStore.showAddressBookPopupEnabled;

  @computed
  String get backgroundImage => _settingsStore.backgroundImage;

  @action
  void setBalanceDisplayMode(BalanceDisplayMode value) => _settingsStore.balanceDisplayMode = value;

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
    await setTheme(newTheme);
    await setThemeMode(newTheme.themeMode);
  }

  @action
  Future<void> setTheme(MaterialThemeBase newTheme) async {
    await _themeStore.setTheme(newTheme);
  }

  @action
  Future<void> setThemeMode(ThemeMode value) async {
    await _themeStore.setThemeMode(value);
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
  void setBackgroundImage(String path) => _settingsStore.backgroundImage = path;
}
