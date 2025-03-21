import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/alert_with_no_action.dart.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BackgroundSyncPage extends BasePage {
  BackgroundSyncPage(this.dashboardViewModel);

  @override
  String get title => S.current.background_sync;

  final DashboardViewModel dashboardViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dashboardViewModel.hasBatteryOptimization)
            Observer(builder: (context) {
              return SettingsSwitcherCell(
                title: S.current.unrestricted_background_service,
                value: !dashboardViewModel.batteryOptimizationEnabled,
                onValueChange: (_, bool value) {
                  dashboardViewModel.disableBatteryOptimization();
                },
              );
            }),
          Observer(builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.background_sync,
              value: dashboardViewModel.backgroundSyncEnabled,
              onValueChange: dashboardViewModel.batteryOptimizationEnabled ? (_, bool value) {
                unawaited(showPopUp(context: context, builder: (context) => AlertWithOneAction(
                  alertTitle: S.current.background_sync,
                  alertContent: S.current.unrestricted_background_service_notice,
                  buttonText: S.current.ok,
                  buttonAction: () => Navigator.of(context).pop(),
                )));
              } : (_, bool value) {
                if (value) {
                  dashboardViewModel.enableBackgroundSync();
                } else {
                  dashboardViewModel.disableBackgroundSync();
                }
              },
            );
          }),
          Observer(builder: (context) {
            return SettingsPickerCell<SyncMode>(
                title: S.current.background_sync_mode,
                items: SyncMode.all,
                displayItem: (SyncMode syncMode) => syncMode.name,
                selectedItem: dashboardViewModel.syncMode,
                onItemSelected: (syncMode) async {
                  dashboardViewModel.setSyncMode(syncMode);
                });
          }),
          
          // Observer(builder: (context) {
          //   return SettingsSwitcherCell(
          //     title: S.current.background_sync_on_battery,
          //     value: dashboardViewModel.backgroundSyncOnBattery,
          //     onValueChange: (_, bool value) =>
          //         dashboardViewModel.setBackgroundSyncOnBattery(value),
          //   );
          // }),
          // Observer(builder: (context) {
          //   return SettingsSwitcherCell(
          //     title: S.current.background_sync_on_data,
          //     value: dashboardViewModel.backgroundSyncOnData,
          //     onValueChange: (_, bool value) => dashboardViewModel.setBackgroundSyncOnData(value),
          //   );
          // }),
        ],
      ),
    );
  }
}
