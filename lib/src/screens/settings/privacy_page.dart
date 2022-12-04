import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/privacy_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PrivacyPage extends BasePage {
  PrivacyPage(this._privacySettingsViewModel);

  @override
  String get title => S.current.privacy_settings;

  final PrivacySettingsViewModel _privacySettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Observer(builder: (_) {
        return Observer(builder: (_) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsSwitcherCell(
                  title: S.current.disable_exchange,
                  value: _privacySettingsViewModel.disableExchange,
                  onValueChange: (BuildContext context, bool value) {
                    _privacySettingsViewModel.setEnableExchange(value);
                  }),
              SettingsSwitcherCell(
                  title: S.current.settings_save_recipient_address,
                  value: _privacySettingsViewModel.shouldSaveRecipientAddress,
                  onValueChange: (BuildContext _, bool value) {
                    _privacySettingsViewModel.setShouldSaveRecipientAddress(value);
                  })
            ],
          );
        });
      }),
    );
  }
}
