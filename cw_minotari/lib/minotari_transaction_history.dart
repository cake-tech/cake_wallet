import 'package:cw_core/transaction_history.dart';
import 'package:cw_minotari/minotari_transaction_info.dart';
import 'package:mobx/mobx.dart';

part 'minotari_transaction_history.g.dart';

class MinotariTransactionHistory = MinotariTransactionHistoryBase
    with _$MinotariTransactionHistory;

abstract class MinotariTransactionHistoryBase
    extends TransactionHistoryBase<MinotariTransactionInfo> with Store {
  MinotariTransactionHistoryBase();

  @override
  Future<void> save() async {
    // Transaction history is managed by the Rust layer
  }

  @override
  void addOne(MinotariTransactionInfo transaction) {
    transactions[transaction.id] = transaction;
  }

  @override
  void addMany(Map<String, MinotariTransactionInfo> transactions) {
    this.transactions.addAll(transactions);
  }

  Future<void> update() async {
    // TODO: Fetch transactions from FFI layer
  }
}
