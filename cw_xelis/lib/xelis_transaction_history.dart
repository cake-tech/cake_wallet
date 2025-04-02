import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_xelis/xelis_transaction_info.dart';

part 'xelis_transaction_history.g.dart';

class XelisTransactionHistory = XelisTransactionHistoryBase with _$XelisTransactionHistory;

abstract class XelisTransactionHistoryBase
    extends TransactionHistoryBase<XelisTransactionInfo> with Store {
  XelisTransactionHistoryBase() {
    transactions = ObservableMap<String, XelisTransactionInfo>();
  }

  @override
  Future<void> save() async {
    // possible TODO
  }

  @override
  void addOne(XelisTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, XelisTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);
}
