import 'dart:io';

import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cake_wallet/main.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/di.dart';

const moneroSyncTaskKey = "com.cake_wallet.monero_sync_task";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case moneroSyncTaskKey:
        /// The work manager runs on a separate isolate from the main flutter isolate.
        /// thus we initialize app configs first; hive, getIt, etc...
          await initializeAppConfigs();

          final walletLoadingService = getIt.get<WalletLoadingService>();

          final List<WalletListItem> moneroWallets = getIt.get<WalletListViewModel>()
              .wallets.where((element) => element.type == WalletType.monero).toList();

          for (int i=0;i<moneroWallets.length;i++) {
            await walletLoadingService.load(WalletType.monero, moneroWallets[i].name);
          }

          break;
      }

      return Future.value(true);
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
      return Future.error(error);
    }
  });
}

class BackgroundTasks {
  void registerSyncTask({bool changeExisting = false}) async {
    try {
      /// if its not android or the user has no monero wallets
      if (!Platform.isAndroid ||
          !getIt.get<WalletListViewModel>().wallets.any((element) => element.type == WalletType.monero)) {
        return;
      }

      final SyncMode syncMode = getIt.get<SettingsViewModel>().syncMode;

      if (syncMode.type == SyncType.disabled) {
        cancelSyncTask();
        return;
      }

      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      await Workmanager().registerPeriodicTask(
          moneroSyncTaskKey,
          moneroSyncTaskKey,
          initialDelay: syncMode.frequency,
          frequency: syncMode.frequency,
          existingWorkPolicy: changeExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: syncMode.type == SyncType.unobtrusive,
            requiresCharging: syncMode.type == SyncType.unobtrusive,
            requiresDeviceIdle: syncMode.type == SyncType.unobtrusive,
          )
      );
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }

  void cancelSyncTask() {
    try {
      Workmanager().cancelByUniqueName(moneroSyncTaskKey);
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }
}
