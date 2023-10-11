import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:workmanager/workmanager.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/di.dart';

const moneroSyncTaskKey = "com.fotolockr.cakewallet.monero_sync_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Workmanager().executeTask((task, inputData) async {
  //   try {
  //     switch (task) {
  //       case moneroSyncTaskKey:

  //         /// The work manager runs on a separate isolate from the main flutter isolate.
  //         /// thus we initialize app configs first; hive, getIt, etc...
  //         await initializeAppConfigs();

  //         final walletLoadingService = getIt.get<WalletLoadingService>();

  //         final node = getIt.get<SettingsStore>().getCurrentNode(WalletType.monero);

  //         final typeRaw = getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType);

  //         WalletBase? wallet;

  //         if (inputData!['sync_all'] as bool) {
  //           /// get all Monero wallets of the user and sync them
  //           final List<WalletListItem> moneroWallets = getIt
  //               .get<WalletListViewModel>()
  //               .wallets
  //               .where((element) => element.type == WalletType.monero)
  //               .toList();

  //           for (int i = 0; i < moneroWallets.length; i++) {
  //             wallet = await walletLoadingService.load(WalletType.monero, moneroWallets[i].name);

  //             await wallet.connectToNode(node: node);
  //             await wallet.startSync();
  //           }
  //         } else {
  //           /// if the user chose to sync only active wallet
  //           /// if the current wallet is monero; sync it only
  //           if (typeRaw == WalletType.monero.index) {
  //             final name =
  //                 getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);

  //             wallet = await walletLoadingService.load(WalletType.monero, name!);

  //             await wallet.connectToNode(node: node);
  //             await wallet.startSync();
  //           }
  //         }

  //         if (wallet?.syncStatus.progress() == null) {
  //           return Future.error("No Monero wallet found");
  //         }

  //         for (int i = 0;; i++) {
  //           await Future<void>.delayed(const Duration(seconds: 1));
  //           if (wallet?.syncStatus.progress() == 1.0) {
  //             break;
  //           }
  //           if (i > 600) {
  //             return Future.error("Synchronization Timed out");
  //           }
  //         }
  //         break;
  //     }

  //     return Future.value(true);
  //   } catch (error, stackTrace) {
  //     print(error);
  //     print(stackTrace);
  //     return Future.error(error);
  //   }
  // });
}

class BackgroundTasks {
  void registerSyncTask({bool changeExisting = false}) async {
    try {
      bool hasMonero = getIt
          .get<WalletListViewModel>()
          .wallets
          .any((element) => element.type == WalletType.monero);

      /// if its not android nor ios, or the user has no monero wallets; exit
      if (!DeviceInfo.instance.isMobile || !hasMonero) {
        return;
      }

      final settingsStore = getIt.get<SettingsStore>();

      final SyncMode syncMode = settingsStore.currentSyncMode;
      final bool syncAll = settingsStore.currentSyncAll;

      late int fetchInterval;
      switch (syncMode.type) {
        case SyncType.unobtrusive:
          fetchInterval = 1440; // 1 day
          break;
        case SyncType.aggressive:
          fetchInterval = 15; // minutes
          break;
        case SyncType.disabled:
          cancelSyncTask();
          return;
      }

      int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: fetchInterval,
          enableHeadless: syncMode.type == SyncType.aggressive, // android only
          stopOnTerminate: syncMode.type != SyncType.aggressive, // android only
          startOnBoot: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiredNetworkType: NetworkType.NONE,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        // event handler:
        (String taskId) async {
          // This is the fetch-event callback.
          print("[BackgroundFetch] Event received $taskId");

          /// The work manager runs on a separate isolate from the main flutter isolate.
          /// thus we initialize app configs first; hive, getIt, etc...
          await initializeAppConfigs();

          final walletLoadingService = getIt.get<WalletLoadingService>();

          final node = getIt.get<SettingsStore>().getCurrentNode(WalletType.monero);

          final typeRaw = getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType);

          WalletBase? wallet;

          /// get all Monero wallets of the user and sync them
          final List<WalletListItem> moneroWallets = getIt
              .get<WalletListViewModel>()
              .wallets
              .where((element) => element.type == WalletType.monero)
              .toList();

          for (int i = 0; i < moneroWallets.length; i++) {
            wallet = await walletLoadingService.load(WalletType.monero, moneroWallets[i].name);

            await wallet.connectToNode(node: node);
            await wallet.startSync();
          }

          // TODO:
          // /// if the user chose to sync only active wallet
          // /// if the current wallet is monero; sync it only
          // if (typeRaw == WalletType.monero.index) {
          //   final name =
          //       getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);

          //   wallet = await walletLoadingService.load(WalletType.monero, name!);

          //   await wallet.connectToNode(node: node);
          //   await wallet.startSync();
          // }

          if (wallet?.syncStatus.progress() == null) {
            return Future.error("No Monero wallet found");
          }

          for (int i = 0;; i++) {
            await Future<void>.delayed(const Duration(seconds: 1));
            if (wallet?.syncStatus.progress() == 1.0) {
              break;
            }
            if (i > 600) {
              return Future.error("Synchronization Timed out");
            }
          }

          // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
          // for taking too long in the background.
          BackgroundFetch.finish(taskId);
        },
        // timeout handler:
        (String taskId) {
          // This task has been completed, another fetch event can be scheduled.
          print("[BackgroundFetch] TASK TIMEOUT $taskId");
        },
      );

      print('[BackgroundFetch] configure success: $status');

      status = await BackgroundFetch.start();
      print('[BackgroundFetch] start success: $status');

      // await Workmanager().initialize(
      //   callbackDispatcher,
      //   isInDebugMode: kDebugMode,
      // );

      // final inputData = <String, dynamic>{"sync_all": syncAll};
      // final constraints = Constraints(
      //   networkType:
      //       syncMode.type == SyncType.unobtrusive ? NetworkType.unmetered : NetworkType.connected,
      //   requiresBatteryNotLow: syncMode.type == SyncType.unobtrusive,
      //   requiresCharging: syncMode.type == SyncType.unobtrusive,
      //   requiresDeviceIdle: syncMode.type == SyncType.unobtrusive,
      // );

      // if (Platform.isIOS) {
      //   await Workmanager().registerOneOffTask(
      //     moneroSyncTaskKey,
      //     moneroSyncTaskKey,
      //     initialDelay: syncMode.frequency,
      //     existingWorkPolicy: ExistingWorkPolicy.replace,
      //     inputData: inputData,
      //     constraints: constraints,
      //   );
      //   return;
      // }

      // await Workmanager().registerPeriodicTask(
      //   moneroSyncTaskKey,
      //   moneroSyncTaskKey,
      //   initialDelay: syncMode.frequency,
      //   frequency: syncMode.frequency,
      //   existingWorkPolicy: changeExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
      //   inputData: inputData,
      //   constraints: constraints,
      // );
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }

  void cancelSyncTask() async {
    try {
      // Workmanager().cancelByUniqueName(moneroSyncTaskKey);
      int status = await BackgroundFetch.stop();
      print('[BackgroundFetch] stop success: $status');
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }
}
