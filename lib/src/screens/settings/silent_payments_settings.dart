import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
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
          ModalTopBar(
            title: S.current.silent_payments_settings,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.current.seed_alert_back,
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Observer(builder: (_) {
                return Container(
                  padding: EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      if (!FeatureFlag.hasNewUi)
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
                      Padding(
                        padding: EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            S.current.silent_payments_always_scan_description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                      SettingsCellWithArrow(
                        title: S.current.rescan,
                        handler: (BuildContext context) =>
                            Navigator.of(context).pushNamed(Routes.rescan),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 8),
                        child: PrimaryButton(
                          text: S.current.silent_payments_resume_scanning,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          isDisabled: _silentPaymentsSettingsViewModel.silentPaymentsAlwaysScan,
                          onPressed: () {
                            _silentPaymentsSettingsViewModel.resumeScanning();
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _silentPaymentsSettingsViewModel.silentPaymentsAlwaysScan
                                ? S.current.silent_payments_resume_scanning_disabled_description
                                : S.current.silent_payments_resume_scanning_description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
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
