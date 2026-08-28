import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';

class DecredTransactionHistory extends TransactionHistory<TransactionInfo> {
  // update returns true if a known transaction that is not pending was found.
  bool update(Map<String, TransactionInfo> txs) {
    var foundOldTx = false;
    txs.forEach((_, tx) {
      final existing = transactions[tx.id];
      if (existing == null || existing.isPending) {
        put(tx.id, tx);
      } else {
        foundOldTx = true;
      }
    });
    return foundOldTx;
  }
}
