import 'dart:async';

import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:connectivity/connectivity.dart';

Timer _checkConnectionTimer;

void startCheckConnectionReaction(WalletBase wallet, SettingsStore settingsStore, {int timeInterval = 5}) {
  _checkConnectionTimer?.cancel();
  _checkConnectionTimer = Timer.periodic(Duration(seconds: timeInterval), (_) async {
    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult == ConnectivityResult.none) {
      wallet.syncStatus = FailedSyncStatus();
      return;
    }

    if (wallet.syncStatus is LostConnectionSyncStatus ||
        wallet.syncStatus is FailedSyncStatus) {
      try {
        final alive =
            await settingsStore.getCurrentNode(wallet.type).requestNode();

        if (alive) {
          await wallet.connectToNode(
              node: settingsStore.getCurrentNode(wallet.type));
        }
      } catch (_) {
        // FIXME: empty catch clojure
      }
    }
  });
}
