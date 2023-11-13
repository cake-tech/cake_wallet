import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/privacy_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TrocadorProvidersPage extends BasePage {
  TrocadorProvidersPage(this._privacySettingsViewModel);

  @override
  String get title => 'Trocador Providers';

  final PrivacySettingsViewModel _privacySettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Observer(builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsSwitcherCell(
                title: 'Provider 1',
                value: false,
                onValueChange: (BuildContext _, bool value) {
                }),
            SettingsSwitcherCell(
                title: 'Provider 2',
                value: false,
                onValueChange: (BuildContext _, bool value) {
                }),
            SettingsSwitcherCell(
                title: 'Provider 3',
                value: false,
                onValueChange: (BuildContext _, bool value) {
                }),
              SettingsSwitcherCell(
                  title: 'Provider 4',
                  value: false,
                  onValueChange: (BuildContext _, bool value) {
                  }),
          ],
        );
      }),
    );
  }
}
