import 'dart:async';

import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cw_bitcoin/payjoin/storage.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'payjoin_transactions_store.g.dart';

class PayjoinTransactionsStore = PayjoinTransactionsStoreBase with _$PayjoinTransactionsStore;

abstract class PayjoinTransactionsStoreBase with Store {
  PayjoinTransactionsStoreBase({
    required this.storage,
  }) : transactions = <PayjoinTransactionListItem>[] {
    storageChangesSubscription = PayjoinStorage.changes.listen((_) => updateTransactionList());
    updateTransactionList();
  }

  final PayjoinStorage storage;

  /// Fires after every session mutation in any [PayjoinStorage] instance.
  late final StreamSubscription<void> storageChangesSubscription;

  @observable
  List<PayjoinTransactionListItem> transactions;

  Future<void> dispose() async {
    await storageChangesSubscription.cancel();
  }

  @action
  Future<void> updateTransactionList() async {
    final updatedTransactions = <PayjoinTransactionListItem>[];
    final sessions = await storage.readAllWithKeys();
    for (final entry in sessions) {
      final key = entry.key;
      final session = entry.value;
      // Hide sessions that used fallback (the underlying regular tx displays
      // instead). Cancelled / unrecoverable sessions without a stored PSBT are
      // also hidden (no way to recover or broadcast). Success sessions are
      // always shown even without a txId — the receiver never broadcasts, so
      // txId is optional metadata from PSBT parsing; absence doesn't mean
      // failure.
      final hasFallbackPsbt = session.originalPsbt?.isNotEmpty == true;
      final isTerminalWithoutFallback =
          (session.status == PayjoinSessionStatus.unrecoverable.name ||
                  session.status == PayjoinSessionStatus.cancelled.name) &&
              !hasFallbackPsbt;
      final isHidden = isTerminalWithoutFallback || session.usedFallback;

      if (!isHidden &&
          session.inProgressSince != null &&
          [
            PayjoinSessionStatus.inProgress.name,
            PayjoinSessionStatus.success.name,
            PayjoinSessionStatus.unrecoverable.name,
            PayjoinSessionStatus.cancelled.name,
          ].contains(session.status)) {
        updatedTransactions.add(PayjoinTransactionListItem(
          sessionId: key,
          session: session,
          key: ValueKey('payjoin_transaction_list_item_${key}_key'),
        ));
      }
    }

    transactions = updatedTransactions;
  }
}
