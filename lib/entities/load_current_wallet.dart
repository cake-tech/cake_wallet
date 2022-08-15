import 'dart:io';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/main.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:workmanager/workmanager.dart';

const moneroSyncTaskKey = "com.cake_wallet.monero_sync_task";

Future<void> loadCurrentWallet() async {
  final appStore = getIt.get<AppStore>();
  final name = getIt
      .get<SharedPreferences>()
      .getString(PreferencesKey.currentWalletName);
  final typeRaw =
      getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType) ??
          0;
  final type = deserializeFromInt(typeRaw);
  final walletLoadingService = getIt.get<WalletLoadingService>();
  if (type == WalletType.monero && Platform.isAndroid) {
    registerSyncTask();
  } else {
    cancelSyncTask();
  }
  final wallet = await walletLoadingService.load(type, name);
  appStore.changeCurrentWallet(wallet);
}

void registerSyncTask() async {
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    await Workmanager().registerPeriodicTask(
      moneroSyncTaskKey,
      moneroSyncTaskKey,
      // TODO: change duration to the desired intervals to run this task
      initialDelay: const Duration(hours: 1),
      frequency: Duration(hours: 1),
    );
  } catch (error, stackTrace) {
    print(error);
    print(stackTrace);
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case moneroSyncTaskKey:

          /// The work manager runs on a separate isolate from the main flutter isolate.
          /// thus we initialize app configs first; hive, getIt, etc...
          await initializeAppConfigs();
          await loadCurrentWallet();
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

void cancelSyncTask() {
  try {
    Workmanager().cancelByUniqueName(moneroSyncTaskKey);
  } catch (error, stackTrace) {
    print(error);
    print(stackTrace);
  }
}
