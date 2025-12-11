import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_monerolws/lws_transaction_info.dart';

part 'lws_transaction_history.g.dart';

class MoneroTransactionHistory = MoneroTransactionHistoryBase with _$MoneroTransactionHistory;

abstract class MoneroTransactionHistoryBase extends TransactionHistoryBase<MoneroTransactionInfo> with Store {
  MoneroTransactionHistoryBase() {
    transactions = ObservableMap<String, MoneroTransactionInfo>();
  }

  @override
  Future<void> save() async {}

  @override
  void addOne(MoneroTransactionInfo transaction) => transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, MoneroTransactionInfo> transactions) => this.transactions.addAll(transactions);
}
