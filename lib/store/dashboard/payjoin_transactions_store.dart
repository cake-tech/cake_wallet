import 'dart:async';

import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'payjoin_transactions_store.g.dart';

class PayjoinTransactionsStore = PayjoinTransactionsStoreBase with _$PayjoinTransactionsStore;

abstract class PayjoinTransactionsStoreBase with Store {
  PayjoinTransactionsStoreBase({
    required this.payjoinSessionSource,
  }) : transactions = <PayjoinTransactionListItem>[] {
    payjoinSessionSource.watch().listen((_) => updateTransactionList());
    updateTransactionList();
  }

  Box<PayjoinSession> payjoinSessionSource;

  @observable
  List<PayjoinTransactionListItem> transactions;

  @action
  Future<void> updateTransactionList() async {
    final updatedTransactions = <PayjoinTransactionListItem>[];
    payjoinSessionSource.toMap().forEach((dynamic key, PayjoinSession session) {
      // Hide sessions that used fallback (the underlying regular tx displays
      // instead). Unrecoverable without a stored PSBT is also hidden (no way
      // to recover or broadcast). Success sessions are always shown even
      // without a txId — the receiver never broadcasts, so txId is optional
      // metadata from PSBT parsing; absence doesn't mean failure.
      final hasFallbackPsbt = session.originalPsbt?.isNotEmpty == true;
      final isHidden =
          (session.status == PayjoinSessionStatus.unrecoverable.name &&
              !hasFallbackPsbt) ||
          session.usedFallback;

      if (!isHidden &&
          session.inProgressSince != null &&
          [
            PayjoinSessionStatus.inProgress.name,
            PayjoinSessionStatus.success.name,
            PayjoinSessionStatus.unrecoverable.name,
          ].contains(session.status)) {
        updatedTransactions.add(PayjoinTransactionListItem(
          sessionId: key as String,
          session: session,
          key: ValueKey('payjoin_transaction_list_item_${key}_key'),
        ));
      }
    });

    transactions = updatedTransactions;
  }
}
