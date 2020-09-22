import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/sync_status.dart';

ReactionDisposer _onWalletSyncStatusChangeReaction;

void startWalletSyncStatusChangeReaction(WalletBase wallet) {
  _onWalletSyncStatusChangeReaction?.reaction?.dispose();
  _onWalletSyncStatusChangeReaction =
      reaction((_) => wallet.syncStatus, (SyncStatus status) async {
        if (status is ConnectedSyncStatus) {
          await wallet.startSync();
        }
      });
}