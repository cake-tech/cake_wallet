import 'dart:async';

import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/entities/update_haven_rate.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'fiat_historical_rate_update.dart';

ReactionDisposer? _onWalletSyncStatusChangeReaction;
Timer? _debounceTimer;

void startWalletSyncStatusChangeReaction(
    WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet,
    FiatConversionStore fiatConversionStore,
    SettingsStore settingsStore,
    Box<TransactionDescription> transactionDescription) {
  _onWalletSyncStatusChangeReaction?.reaction.dispose();
  _onWalletSyncStatusChangeReaction = reaction((_) => wallet.syncStatus, (SyncStatus status) async {
    try {
      if (status is ConnectedSyncStatus) {
        await wallet.startSync();
        if (wallet.type == WalletType.haven) {
          await updateHavenRate(fiatConversionStore);
        }
      }
      if (status is SyncingSyncStatus) {
        await WakelockPlus.enable();
      }
      if (status is SyncedSyncStatus || status is FailedSyncStatus) {
        await WakelockPlus.disable();

        if (status is SyncedSyncStatus &&
            (settingsStore.fiatApiMode != FiatApiMode.disabled ||
                settingsStore.showHistoricalFiatAmount)) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(Duration(milliseconds: 100), () async {
            await historicalRateUpdate(
                wallet, settingsStore, fiatConversionStore, transactionDescription);
          });
        }
      }
    } catch (e) {
      print(e.toString());
    }
  });
}
