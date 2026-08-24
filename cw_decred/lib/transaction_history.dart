import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';

class DecredTransactionHistory extends TransactionHistory<TransactionInfo> {
  /// Returns true if a known, already-confirmed transaction was seen — the
  /// caller uses that to stop walking further back through history.
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
