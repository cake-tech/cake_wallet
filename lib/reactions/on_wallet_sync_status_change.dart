import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/balance.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/entities/sync_status.dart';

ReactionDisposer _onWalletSyncStatusChangeReaction;

void startWalletSyncStatusChangeReaction(
    WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
            TransactionInfo>
        wallet) {
  _onWalletSyncStatusChangeReaction?.reaction?.dispose();
  _onWalletSyncStatusChangeReaction =
      reaction((_) => wallet.syncStatus, (SyncStatus status) async {
    if (status is ConnectedSyncStatus) {
      await wallet.startSync();
    }
  });
}
