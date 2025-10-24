import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

ReactionDisposer? _onWalletSyncStatusChangeReaction;

void startWalletSyncStatusChangeReaction(
    WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet,
    SettingsStore settingsStore) {
  _onWalletSyncStatusChangeReaction?.reaction.dispose();
  _onWalletSyncStatusChangeReaction = reaction((_) => wallet.syncStatus, (SyncStatus status) async {
    try {
      if (status is ConnectedSyncStatus) {
        await wallet.startSync();
      }
      if (status is SyncingSyncStatus || status is ProcessingSyncStatus) {
        await WakelockPlus.enable();
      }
      if (status is SyncedSyncStatus || status is FailedSyncStatus) {
        await WakelockPlus.disable();
        // Reset sync start time when sync completes or fails
        SyncingSyncStatus.resetSyncStartTime();
      }

      if (status is SyncedSyncStatus &&
          wallet.type == WalletType.bitcoin &&
          settingsStore.usePayjoin) {
        bitcoin!.resumePayjoinSessions(wallet);
      }
    } catch (e) {
      printV(e.toString());
    }
  });
}
