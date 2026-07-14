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
      // Hide ghost rows: sessions marked success but with no txId (failed
      // without producing a transaction). Also hide sessions that fell back to
      // the fallback tx so the underlying regular transaction is displayed
      // instead of a payjoin row.
      final isSuccess = session.status == PayjoinSessionStatus.success.name;
      final hasTxId = session.txId != null && session.txId!.isNotEmpty;
      final isHidden =
          session.status == PayjoinSessionStatus.unrecoverable.name ||
          session.usedFallback ||
          (isSuccess && !hasTxId);

      if (!isHidden &&
          session.inProgressSince != null &&
          [
            PayjoinSessionStatus.inProgress.name,
            PayjoinSessionStatus.success.name,
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
