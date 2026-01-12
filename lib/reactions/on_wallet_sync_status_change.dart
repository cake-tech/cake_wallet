import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
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
        SyncingSyncStatus.resetSyncStartTime();
        await wallet.startSync();
      }

      if (status is SyncingSyncStatus || status is ProcessingSyncStatus) {
        await WakelockPlus.enable();
      }

      if (status is SyncedSyncStatus) {
        await WakelockPlus.disable();
        SyncingSyncStatus.resetSyncStartTime();
        SyncingSyncStatus.blockHistory.clear();
        try {
          final walletListViewModel = getIt.get<WalletListViewModel>();
          await walletListViewModel.updateList();
        } catch (e) {
          printV("Error refreshing wallet list after sync: $e");
        }
      }

      if (status is FailedSyncStatus) {
        await WakelockPlus.disable();
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
