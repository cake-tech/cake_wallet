import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/privacy_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DomainLookupsPage extends BasePage {
  DomainLookupsPage(this._privacySettingsViewModel);

  @override
  String get title => "S.current.display_settings";

  final PrivacySettingsViewModel _privacySettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Observer(builder: (_) {
        return Container(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            children: [
              SettingsSwitcherCell(
                  title: 'S.current.settings_display_balance',
                  value: _privacySettingsViewModel.lookupTwitter,
                  onValueChange: (_, bool value) => _privacySettingsViewModel.setLookupTwitter(value)),
              SettingsSwitcherCell(
                  title: 'S.current.settings_display_balance',
                  value: _privacySettingsViewModel.looksUpMastodon,
                  onValueChange: (_, bool value) => _privacySettingsViewModel.setLooksUpMastodon(value)),
              SettingsSwitcherCell(
                  title: 'S.current.settings_display_balance',
                  value: _privacySettingsViewModel.looksUpYatService,
                  onValueChange: (_, bool value) => _privacySettingsViewModel.setLooksUpYatService(value)),
              SettingsSwitcherCell(
                  title: 'S.current.settings_display_balance',
                  value: _privacySettingsViewModel.looksUpUnstoppableDomains,
                  onValueChange: (_, bool value) => _privacySettingsViewModel.setLooksUpUnstoppableDomains(value)),
              SettingsSwitcherCell(
                  title: 'S.current.settings_display_balance',
                  value: _privacySettingsViewModel.looksUpOpenAlias,
                  onValueChange: (_, bool value) => _privacySettingsViewModel.setLooksUpOpenAlias(value)),
              SettingsSwitcherCell(
                  title: 'S.current.settings_display_balance',
                  value: _privacySettingsViewModel.looksUpENS,
                  onValueChange: (_, bool value) => _privacySettingsViewModel.setLooksUpENS(value)),

              //if (!isHaven) it does not work correctly
            ],
          ),
        );
      }),
    );
  }
}
