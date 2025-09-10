import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/silent_payments_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SilentPaymentsSettingsPage extends BasePage {
  SilentPaymentsSettingsPage(this._silentPaymentsSettingsViewModel);

  @override
  String get title => S.current.silent_payments_settings;

  final SilentPaymentsSettingsViewModel _silentPaymentsSettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Observer(builder: (_) {
        return Container(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            children: [
              SettingsSwitcherCell(
                currentTheme: currentTheme,
                title: S.current.silent_payments_display_card,
                value: _silentPaymentsSettingsViewModel.silentPaymentsCardDisplay,
                onValueChange: (_, bool value) {
                  _silentPaymentsSettingsViewModel.setSilentPaymentsCardDisplay(value);
                },
              ),
              SettingsSwitcherCell(
                currentTheme: currentTheme,
                title: S.current.silent_payments_always_scan,
                value: _silentPaymentsSettingsViewModel.silentPaymentsAlwaysScan,
                onValueChange: (_, bool value) {
                  _silentPaymentsSettingsViewModel.setSilentPaymentsAlwaysScan(value);
                },
              ),
              SettingsCellWithArrow(
                title: S.current.silent_payments_scanning,
                handler: (BuildContext context) => Navigator.of(context).pushNamed(Routes.rescan),
              ),
              SettingsCellWithArrow(
                title: S.current.silent_payments_logs,
                handler: (BuildContext context) =>
                    Navigator.of(context).pushNamed(Routes.silentPaymentsLogs),
              ),
            ],
          ),
        );
      }),
    );
  }
}
