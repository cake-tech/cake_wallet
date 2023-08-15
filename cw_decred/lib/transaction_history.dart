import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_history.dart';

// NOTE: Methods currently not used.
class DecredTransactionHistory extends TransactionHistoryBase<TransactionInfo> {
  DecredTransactionHistory() {
    transactions = ObservableMap<String, TransactionInfo>();
  }

  Future<void> init() async {}

  @override
  void addOne(TransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, TransactionInfo> transactions) =>
      this.transactions.addAll(transactions);

  @override
  Future<void> save() async {}

  Future<void> changePassword(String password) async {}

  void _update(TransactionInfo transaction) =>
      transactions[transaction.id] = transaction;
}
