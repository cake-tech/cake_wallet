import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_haven/haven_transaction_info.dart';

part 'haven_transaction_history.g.dart';

class HavenTransactionHistory = HavenTransactionHistoryBase
    with _$HavenTransactionHistory;

abstract class HavenTransactionHistoryBase
    extends TransactionHistoryBase<HavenTransactionInfo> with Store {
  HavenTransactionHistoryBase() {
    transactions = ObservableMap<String, HavenTransactionInfo>();
  }

  @override
  Future<void> save() async {}

  @override
  void addOne(HavenTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, HavenTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);
}
