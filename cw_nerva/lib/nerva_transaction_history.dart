import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_nerva/nerva_transaction_info.dart';

part 'nerva_transaction_history.g.dart';

class NervaTransactionHistory = NervaTransactionHistoryBase
    with _$NervaTransactionHistory;

abstract class NervaTransactionHistoryBase
    extends TransactionHistoryBase<NervaTransactionInfo> with Store {
  NervaTransactionHistoryBase() {
    transactions = ObservableMap<String, NervaTransactionInfo>();
  }

  @override
  Future<void> save() async {}

  @override
  void addOne(NervaTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, NervaTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);

}
