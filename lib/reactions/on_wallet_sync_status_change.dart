import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/update_haven_rate.dart';
import 'package:cake_wallet/entities/wake_lock.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:flutter/services.dart';

ReactionDisposer? _onWalletSyncStatusChangeReaction;

void startWalletSyncStatusChangeReaction(
    WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
            TransactionInfo> wallet,
    FiatConversionStore fiatConversionStore) {
 //Remove the sync as it will fail at startSync as wallet contents are removed
}
