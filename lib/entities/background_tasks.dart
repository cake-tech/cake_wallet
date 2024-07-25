import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/di.dart';

const moneroSyncTaskKey = "com.fotolockr.cakewallet.monero_sync_task";
const mwebSyncTaskKey = "com.fotolockr.cakewallet.mweb_sync_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case mwebSyncTaskKey:

          /// The work manager runs on a separate isolate from the main flutter isolate.
          /// thus we initialize app configs first; hive, getIt, etc...
          await initializeAppConfigs();

          final List<WalletListItem> ltcWallets = getIt
              .get<WalletListViewModel>()
              .wallets
              .where((element) => [WalletType.litecoin].contains(element.type))
              .toList();

          if (ltcWallets.isEmpty) {
            return Future.error("No ltc wallets found");
          }

          final walletLoadingService = getIt.get<WalletLoadingService>();

          var wallet =
              await walletLoadingService.load(ltcWallets.first.type, ltcWallets.first.name);

          print("STARTING SYNC FROM BG!!");
          // await wallet.startSync();

          // RpcClient _stub = bitcoin!.getMwebStub();

          double syncStatus = 0.0;

          Timer? _syncTimer;

          dynamic _stub = await bitcoin!.getMwebStub(wallet);

          _syncTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
            // if (syncStatus is FailedSyncStatus) return;
            // final height = await electrumClient.getCurrentBlockChainTip() ?? 0;
            final height = 0;
            dynamic resp = await bitcoin!.getStatusRequest(wallet);
            int blockHeaderHeight = resp.blockHeaderHeight as int;
            int mwebHeaderHeight = resp.mwebHeaderHeight as int;
            int mwebUtxosHeight = resp.mwebUtxosHeight as int;

            if (blockHeaderHeight < height) {
              syncStatus = blockHeaderHeight / height;
            } else if (mwebHeaderHeight < height) {
              syncStatus = mwebHeaderHeight / height;
            } else if (mwebUtxosHeight < height) {
              syncStatus = 0.999;
            } else {
              syncStatus = 1;
            }
          });

          for (int i = 0;; i++) {
            await Future<void>.delayed(const Duration(seconds: 1));
            if (syncStatus == 1) {
              print("sync done!");
              break;
            } else {
              print("Sync status ${syncStatus}");
            }
            if (i > 600) {
              return Future.error("Synchronization Timed out");
            }
          }
          _syncTimer?.cancel();

          break;

        case moneroSyncTaskKey:

          /// The work manager runs on a separate isolate from the main flutter isolate.
          /// thus we initialize app configs first; hive, getIt, etc...
          await initializeAppConfigs();

          final walletLoadingService = getIt.get<WalletLoadingService>();

          final typeRaw = getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType);

          WalletBase? wallet;

          if (inputData!['sync_all'] as bool) {
            /// get all Monero wallets of the user and sync them
            final List<WalletListItem> moneroWallets = getIt
                .get<WalletListViewModel>()
                .wallets
                .where((element) => [WalletType.monero, WalletType.wownero].contains(element.type))
                .toList();

            for (int i = 0; i < moneroWallets.length; i++) {
              wallet =
                  await walletLoadingService.load(moneroWallets[i].type, moneroWallets[i].name);
              final node = getIt.get<SettingsStore>().getCurrentNode(moneroWallets[i].type);
              await wallet.connectToNode(node: node);
              await wallet.startSync();
            }
          } else {
            /// if the user chose to sync only active wallet
            /// if the current wallet is monero; sync it only
            if (typeRaw == WalletType.monero.index || typeRaw == WalletType.wownero.index) {
              final name =
                  getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);

              wallet = await walletLoadingService.load(WalletType.values[typeRaw!], name!);
              final node = getIt.get<SettingsStore>().getCurrentNode(WalletType.values[typeRaw]);

              await wallet.connectToNode(node: node);
              await wallet.startSync();
            }
          }

          if (wallet?.syncStatus.progress() == null) {
            return Future.error("No Monero/Wownero wallet found");
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
      bool hasMonero = getIt
          .get<WalletListViewModel>()
          .wallets
          .any((element) => element.type == WalletType.monero);

      bool hasLitecoin = getIt
          .get<WalletListViewModel>()
          .wallets
          .any((element) => element.type == WalletType.litecoin);

      /// if its not android nor ios, or the user has no monero wallets; exit
      if (!DeviceInfo.instance.isMobile || (!hasMonero && !hasLitecoin)) {
        return;
      }

      final settingsStore = getIt.get<SettingsStore>();

      final SyncMode syncMode = settingsStore.currentSyncMode;
      final bool syncAll = settingsStore.currentSyncAll;

      if (syncMode.type == SyncType.disabled || !FeatureFlag.isBackgroundSyncEnabled) {
        cancelSyncTask();
        return;
      }

      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      final inputData = <String, dynamic>{"sync_all": syncAll};
      final constraints = Constraints(
        networkType:
            syncMode.type == SyncType.unobtrusive ? NetworkType.unmetered : NetworkType.connected,
        requiresBatteryNotLow: syncMode.type == SyncType.unobtrusive,
        requiresCharging: syncMode.type == SyncType.unobtrusive,
        requiresDeviceIdle: syncMode.type == SyncType.unobtrusive,
      );

      if (Platform.isIOS && syncMode.type == SyncType.unobtrusive) {
        // await Workmanager().registerOneOffTask(
        //   moneroSyncTaskKey,
        //   moneroSyncTaskKey,
        //   initialDelay: syncMode.frequency,
        //   existingWorkPolicy: ExistingWorkPolicy.replace,
        //   inputData: inputData,
        //   constraints: constraints,
        // );
        await Workmanager().registerOneOffTask(
          mwebSyncTaskKey,
          mwebSyncTaskKey,
          initialDelay: Duration(seconds: 30),
          existingWorkPolicy: ExistingWorkPolicy.replace,
          inputData: inputData,
          constraints: constraints,
        );
        return;
      }

      // await Workmanager().registerPeriodicTask(
      //   moneroSyncTaskKey,
      //   moneroSyncTaskKey,
      //   initialDelay: syncMode.frequency,
      //   frequency: syncMode.frequency,
      //   existingWorkPolicy: changeExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
      //   inputData: inputData,
      //   constraints: constraints,
      // );
      await Workmanager().registerPeriodicTask(
        mwebSyncTaskKey,
        mwebSyncTaskKey,
        initialDelay: syncMode.frequency,
        frequency: syncMode.frequency,
        existingWorkPolicy: changeExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
        inputData: inputData,
        constraints: constraints,
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
