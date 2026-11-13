import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/silent_payments_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SilentPaymentsSettingsPage extends StatelessWidget {
  SilentPaymentsSettingsPage(this._silentPaymentsSettingsViewModel);

  final SilentPaymentsSettingsViewModel _silentPaymentsSettingsViewModel;

  Future<void> _onAlwaysScanChanged(BuildContext context, bool value) async {
    final alwaysScanningOff = !value;
    final canScanFromNode = await _silentPaymentsSettingsViewModel.nodeSupportsSilentPayments;

    // No popup needed: turning scanning off, or the current node already supports it then no change
    if (alwaysScanningOff || canScanFromNode) {
      _silentPaymentsSettingsViewModel.setSilentPaymentsAlwaysScan(value);
      return;
    }

    if (!context.mounted) {
      return;
    }

    // turning scanning on and warning that the node will be switched.
    await showPopUp<void>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(dialogContext).change_current_node_title,
        alertContent: S.of(dialogContext).confirm_silent_payments_switch_node,
        rightButtonText: S.of(dialogContext).confirm,
        leftButtonText: S.of(dialogContext).cancel,
        actionRightButton: () {
          Navigator.of(dialogContext).pop();
          _silentPaymentsSettingsViewModel.setSilentPaymentsAlwaysScan(true);
        },
        actionLeftButton: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

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
                      SettingsSwitcherCell(
                        title: S.current.silent_payments_always_scan,
                        value: _silentPaymentsSettingsViewModel.silentPaymentsAlwaysScan,
                        onValueChange: (_, bool value) => _onAlwaysScanChanged(context, value),
                      ),
                      SettingsCellWithArrow(
                        title: S.current.silent_payments_scanning,
                        handler: (BuildContext context) =>
                            Navigator.of(context).pushNamed(Routes.rescan),
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
