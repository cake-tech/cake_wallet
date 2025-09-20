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
import 'package:permission_handler/permission_handler.dart';

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
          Observer(builder: (context) {
            return SettingsSwitcherCell(
              currentTheme: currentTheme,
              title: S.current.background_sync,
              value: dashboardViewModel.backgroundSyncEnabled,
              onValueChange: (_, bool value) async {
                if (value) {
                  if (dashboardViewModel.batteryOptimizationEnabled) {
                    await showPopUp(context: context, builder: (context) => AlertWithOneAction(
                      alertTitle: S.current.background_sync,
                      alertContent: S.current.unrestricted_background_service_notice,
                      buttonText: S.current.ok,
                      buttonAction: () => Navigator.of(context).pop(),
                    ));
                    await dashboardViewModel.disableBatteryOptimization();
                    for (var i = 0; i < 4 * 60; i++) {
                      await Future.delayed(Duration(milliseconds: 250));
                      if (!dashboardViewModel.batteryOptimizationEnabled) {
                        await dashboardViewModel.enableBackgroundSync();
                        return;
                      }
                    }
                  } else {
                    dashboardViewModel.enableBackgroundSync();
                  }
                } else {
                  dashboardViewModel.disableBackgroundSync();
                }
              },
            );
          }),
          Observer(builder: (context) {
            return SettingsPickerCell<SyncMode>(
              currentTheme: currentTheme,
                title: S.current.background_sync_mode,
                items: SyncMode.all,
                displayItem: (SyncMode syncMode) => syncMode.name,
                selectedItem: dashboardViewModel.settingsStore.currentSyncMode,
                onItemSelected: (dashboardViewModel.batteryOptimizationEnabled && dashboardViewModel.hasBatteryOptimization) ? null : (syncMode) async {
                  dashboardViewModel.setSyncMode(syncMode);
                });
          }),
          if (dashboardViewModel.hasBgsyncNetworkConstraints)
            Observer(builder: (context) {
              return SettingsSwitcherCell(
                currentTheme: currentTheme,
                title: S.current.background_sync_on_unmetered_network,
                value: dashboardViewModel.backgroundSyncNetworkUnmetered,
                onValueChange: (_, bool value) => dashboardViewModel.setBackgroundSyncNetworkUnmetered(value),
              );
            }),
          if (dashboardViewModel.hasBgsyncBatteryNotLowConstraints)
            Observer(builder: (context) {
              return SettingsSwitcherCell(
                currentTheme: currentTheme,
                title: S.current.background_sync_on_battery_low,
                value: !dashboardViewModel.backgroundSyncBatteryNotLow,
                onValueChange: (_, bool value) => dashboardViewModel.setBackgroundSyncBatteryNotLow(!value),
              );
            }),
          if (dashboardViewModel.hasBgsyncChargingConstraints)
            Observer(builder: (context) {
              return SettingsSwitcherCell(
                currentTheme: currentTheme,
                title: S.current.background_sync_on_charging,
                value: dashboardViewModel.backgroundSyncCharging,
                onValueChange: (_, bool value) => dashboardViewModel.setBackgroundSyncCharging(value),
              );
            }),
          if (dashboardViewModel.hasBgsyncDeviceIdleConstraints)
            Observer(builder: (context) {
              return SettingsSwitcherCell(
                currentTheme: currentTheme,
                title: S.current.background_sync_on_device_idle,
                value: dashboardViewModel.backgroundSyncDeviceIdle,
                onValueChange: (_, bool value) => dashboardViewModel.setBackgroundSyncDeviceIdle(value),
              );
            }),
          Observer(builder: (context) {
            return SettingsSwitcherCell(
              currentTheme: currentTheme,
              title: S.current.new_transactions_notifications,
              value: dashboardViewModel.backgroundSyncNotificationsEnabled,
              onValueChange: (_, bool value) { 
                try {
                  dashboardViewModel.setBackgroundSyncNotificationsEnabled(value);
                } catch (e) {
                  showPopUp(context: context, builder: (context) => AlertWithOneAction(
                    alertTitle: S.current.error,
                    alertContent: S.current.notification_permission_denied,
                    buttonText: S.current.ok,
                    buttonAction: () {
                      Navigator.of(context).pop();
                    },
                  ));
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
