import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/mweb_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class MwebSettingsPage extends BasePage {
  MwebSettingsPage(this._mwebSettingsViewModel);

  @override
  String get title => S.current.litecoin_mweb_settings;

  final MwebSettingsViewModel _mwebSettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Observer(builder: (_) {
        return Container(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            children: [
              SettingsSwitcherCell(
                title: S.current.litecoin_mweb_display_card,
                value: _mwebSettingsViewModel.mwebCardDisplay,
                onValueChange: (_, bool value) {
                  _mwebSettingsViewModel.setMwebCardDisplay(value);
                },
              ),
              SettingsSwitcherCell(
                title: S.current.litecoin_mweb_enable,
                value: _mwebSettingsViewModel.mwebEnabled,
                onValueChange: (_, bool value) {
                  _mwebSettingsViewModel.setMwebEnabled(value);
                },
              ),
              SettingsCellWithArrow(
                title: S.current.litecoin_mweb_scanning,
                handler: (BuildContext context) => Navigator.of(context).pushNamed(Routes.rescan),
              ),
            SettingsCellWithArrow(
                title: S.current.litecoin_mweb_logs,
                handler: (BuildContext context) => Navigator.of(context).pushNamed(Routes.mwebLogs),
              ),
              SettingsCellWithArrow(
                title: S.current.litecoin_mweb_node,
                handler: (BuildContext context) => Navigator.of(context).pushNamed(Routes.mwebNode),
              ),
            ],
          ),
        );
      }),
    );
  }
}
