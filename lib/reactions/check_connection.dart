import 'dart:async';

import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/utils/tor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/evm/evm.dart';

Timer? _checkConnectionTimer;

void startCheckConnectionReaction(WalletBase wallet, SettingsStore settingsStore,
    {int timeInterval = 5}) {
  _checkConnectionTimer?.cancel();
  // TODO: check the validity of this code, and if it's working fine, then no need for
  // having the connect function in electrum.dart when the syncstatus is lost or failed and add the not connected state
  _checkConnectionTimer = Timer.periodic(Duration(seconds: timeInterval), (_) async {
    if (wallet.type == WalletType.bitcoin && wallet.syncStatus is SyncingSyncStatus) {
      return;
    }
    if (wallet.type == WalletType.decred && wallet.syncStatus is ProcessingSyncStatus) {
      return;
    }

    try {
      final connectivityResult = await (Connectivity().checkConnectivity());

      if (connectivityResult.contains(ConnectivityResult.none)) {
        wallet.syncStatus = FailedSyncStatus();
        return;
      }

      if (wallet.type != WalletType.bitcoin &&
          (wallet.syncStatus is LostConnectionSyncStatus ||
              wallet.syncStatus is FailedSyncStatus)) {
        int? chainId;
        if (isEVMCompatibleChain(wallet.type)) {
          chainId = evm!.getSelectedChainId(wallet);
        }

        final node = settingsStore.getCurrentNode(wallet.type, chainId: chainId);
        final alive = await node.requestNode();

        if (alive) {
          if (settingsStore.currentBuiltinTor) {
            await ensureTorStarted(context: null);
          }

          await wallet.connectToNode(node: node);
        }
      }
    } catch (e) {
      printV(e.toString());
    }
  });
}
