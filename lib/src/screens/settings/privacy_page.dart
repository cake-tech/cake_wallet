import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PrivacyPage extends BasePage {
  PrivacyPage(this.settingsViewModel);

  @override
  String get title => S.current.privacy_settings;

  final SettingsViewModel settingsViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Observer(builder: (_) {
        return SettingsSwitcherCell(
            title: S.current.settings_save_recipient_address,
            value: settingsViewModel.shouldSaveRecipientAddress,
            onValueChange: (BuildContext _, bool value) {
              settingsViewModel.setShouldSaveRecipientAddress(value);
            });
      }),
    );
  }
}
