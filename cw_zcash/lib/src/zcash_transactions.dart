import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_history.dart';

class ZcashTransactionHistory extends TransactionHistoryBase<TransactionInfo> {
  ZcashTransactionHistory() {
    transactions = ObservableMap<String, TransactionInfo>();
  }

  @override
  void addMany(Map<String, TransactionInfo> txs) {
    transactions.addAll(txs);
  }

  @override
  void addOne(TransactionInfo txs) {
    transactions[txs.txHash] = txs;
  }

  @override
  Future<void> save() async {
    // transactions
  }
}