import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/wake_lock.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:flutter/services.dart';

ReactionDisposer _onWalletSyncStatusChangeReaction;

void startWalletSyncStatusChangeReaction(
    WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
            TransactionInfo>
        wallet) {
  final _wakeLock = getIt.get<WakeLock>();
  _onWalletSyncStatusChangeReaction?.reaction?.dispose();
  _onWalletSyncStatusChangeReaction =
      reaction((_) => wallet.syncStatus, (SyncStatus status) async {
    if (status is ConnectedSyncStatus) {
      await wallet.startSync();
    }
    if (status is SyncingSyncStatus) {
      await _wakeLock.enableWake();
    }
    if (status is SyncedSyncStatus || status is FailedSyncStatus) {
      await _wakeLock.disableWake();
    }
  });
}
