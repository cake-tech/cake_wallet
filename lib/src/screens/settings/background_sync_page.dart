import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
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
          Observer(builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.background_sync,
              value: dashboardViewModel.backgroundSyncEnabled,
              onValueChange: (_, bool value) {
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

                  if (Platform.isIOS) return;
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
