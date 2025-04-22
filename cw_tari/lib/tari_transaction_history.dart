import 'dart:core';

import 'package:cw_core/transaction_history.dart';
import 'package:cw_tari/tari_transaction_info.dart';
import 'package:mobx/mobx.dart';

part 'tari_transaction_history.g.dart';

class TariTransactionHistory = TariTransactionHistoryBase
    with _$TariTransactionHistory;

abstract class TariTransactionHistoryBase
    extends TransactionHistoryBase<TariTransactionInfo> with Store {
  TariTransactionHistoryBase() {
    transactions = ObservableMap<String, TariTransactionInfo>();
  }

  Future<void> init() async {
    clear();
  }

  @override
  Future<void> save() async {}

  @override
  void addOne(TariTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, TariTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);
}
