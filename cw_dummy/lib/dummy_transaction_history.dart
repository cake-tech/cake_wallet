import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';

import 'dummy_transaction_info.dart';

part 'dummy_transaction_history.g.dart';

class DummyTransactionHistory = DummyTransactionHistoryBase
    with _$DummyTransactionHistory;

abstract class DummyTransactionHistoryBase
    extends TransactionHistoryBase<DummyTransactionInfo> with Store {
  DummyTransactionHistoryBase() {
    transactions = ObservableMap<String, DummyTransactionInfo>();
  }

  @override
  Future<void> save() async {
    throw UnimplementedError;
  }

  @override
  void addOne(DummyTransactionInfo transaction) => transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, DummyTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);
}
