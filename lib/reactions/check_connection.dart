import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cake_wallet/store/settings_store.dart';
Timer? _checkConnectionTimer;

void startCheckConnectionReaction(
    WalletBase wallet, SettingsStore settingsStore,
    {int timeInterval = 5}) {
  _checkConnectionTimer?.cancel();
  _checkConnectionTimer =
      Timer.periodic(Duration(seconds: timeInterval), (_) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());

      if (connectivityResult == ConnectivityResult.none) {
        wallet.syncStatus = FailedSyncStatus();
        return;
      }

      if (wallet.syncStatus is LostConnectionSyncStatus ||
          wallet.syncStatus is FailedSyncStatus) {
        final alive =
            await settingsStore.getCurrentNode(wallet.type).requestNode();

        if (alive) {
          await wallet.connectToNode(
              node: settingsStore.getCurrentNode(wallet.type));
        }
      }
    } catch (e) {
      print(e.toString());
    }
  });
}
