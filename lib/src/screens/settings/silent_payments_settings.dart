import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/settings/silent_payments_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SilentPaymentsSettingsPage extends StatelessWidget {
  SilentPaymentsSettingsPage(this._silentPaymentsSettingsViewModel);

  final SilentPaymentsSettingsViewModel _silentPaymentsSettingsViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(title: S.current.silent_payments_settings,leadingIcon: Icon(Icons.arrow_back_ios_new),onLeadingPressed: Navigator.of(context).pop,),
          Expanded(
            child: SingleChildScrollView(
              child: Observer(builder: (_) {
                return Container(
                  padding: EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      if(!FeatureFlag.hasNewUi)
                      SettingsSwitcherCell(
                        title: S.current.silent_payments_display_card,
                        value: _silentPaymentsSettingsViewModel.silentPaymentsCardDisplay,
                        onValueChange: (_, bool value) {
                          _silentPaymentsSettingsViewModel.setSilentPaymentsCardDisplay(value);
                        },
                      ),
                      SettingsSwitcherCell(
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
            ),
          ),
        ],
      ),
    );
  }
}
