import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_salvium/salvium_transaction_info.dart';

part 'salvium_transaction_history.g.dart';

class SalviumTransactionHistory = SalviumTransactionHistoryBase
    with _$SalviumTransactionHistory;

abstract class SalviumTransactionHistoryBase
    extends TransactionHistoryBase<SalviumTransactionInfo> with Store {
  SalviumTransactionHistoryBase() {
    transactions = ObservableMap<String, SalviumTransactionInfo>();
  }

  @override
  Future<void> save() async {}

  @override
  void addOne(SalviumTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, SalviumTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);
}
