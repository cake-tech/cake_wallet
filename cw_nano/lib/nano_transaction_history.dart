import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_nano/nano_transaction_info.dart';

part 'nano_transaction_history.g.dart';

class NanoTransactionHistory = NanoTransactionHistoryBase
    with _$NanoTransactionHistory;

abstract class NanoTransactionHistoryBase
    extends TransactionHistoryBase<NanoTransactionInfo> with Store {
  NanoTransactionHistoryBase() {
    transactions = ObservableMap<String, NanoTransactionInfo>();
  }

  @override
  Future<void> save() async {}

  @override
  void addOne(NanoTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, MoneroTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);

}
