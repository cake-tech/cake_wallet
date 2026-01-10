import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_history.dart';

class ZcashTransactionHistory extends TransactionHistoryBase<TransactionInfo> {
  ZcashTransactionHistory() {
    transactions = ObservableMap<String, TransactionInfo>();
  }

  @override
  void addMany(final Map<String, TransactionInfo> txs) {
    transactions.addAll(txs);
  }

  @override
  void addOne(final TransactionInfo txs) {
    transactions[txs.txHash] = txs;
  }

  @override
  Future<void> save() async {
    // No need to save anything, backend is taking care of that
  }
}
