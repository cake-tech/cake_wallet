import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/theme_changer.dart';
import 'package:cake_wallet/themes.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/widgets/standart_switch.dart';

class SettingsSwitchListRow extends StatelessWidget {
  final String title;

  SettingsSwitchListRow({@required this.title});

  Widget _getSwitch(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);
    ThemeChanger _themeChanger = Provider.of<ThemeChanger>(context);

    if (settingsStore.itemHeaders[title] ==
        S.of(context).settings_save_recipient_address) {
      return Observer(
          builder: (_) => StandartSwitch(
              value: settingsStore.shouldSaveRecipientAddress,
              onTaped: () {
                bool _currentValue = !settingsStore.shouldSaveRecipientAddress;
                settingsStore.setSaveRecipientAddress(
                    shouldSaveRecipientAddress: _currentValue);
              }));
    }

    if (settingsStore.itemHeaders[title] ==
        S.of(context).settings_allow_biometrical_authentication) {
      return Observer(
          builder: (_) => StandartSwitch(
              value: settingsStore.allowBiometricalAuthentication,
              onTaped: () {
                bool _currentValue =
                    !settingsStore.allowBiometricalAuthentication;
                settingsStore.setAllowBiometricalAuthentication(
                    allowBiometricalAuthentication: _currentValue);
              }));
    }

    if (settingsStore.itemHeaders[title] == S.of(context).settings_dark_mode) {
      return Observer(
          builder: (_) => StandartSwitch(
              value: settingsStore.isDarkTheme,
              onTaped: () {
                bool _currentValue = !settingsStore.isDarkTheme;
                settingsStore.saveDarkTheme(isDarkTheme: _currentValue);
                _themeChanger.setTheme(
                    _currentValue ? Themes.darkTheme : Themes.lightTheme);
              }));
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);

    return Container(
      color: Theme.of(context).accentTextTheme.headline.backgroundColor,
      child: ListTile(
          contentPadding: EdgeInsets.only(left: 20.0, right: 20.0),
          title: Observer(
            builder: (_) => Text(settingsStore.itemHeaders[title],
                style: TextStyle(
                    fontSize: 16.0,
                    color: Theme.of(context).primaryTextTheme.title.color)),
          ),
          trailing: _getSwitch(context)),
    );
  }
}
