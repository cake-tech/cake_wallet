import 'package:cw_core/pending_transaction.dart';
import 'package:cw_decred/amount_format.dart';

class DecredPendingTransaction with PendingTransaction {
  DecredPendingTransaction(
      {required this.txid,
      required this.amount,
      required this.fee,
      required this.rawHex});

  final int amount;
  final int fee;
  final String txid;
  final String rawHex;

  @override
  String get id => txid;

  @override
  String get amountFormatted => decredAmountToString(amount: amount);

  @override
  String get feeFormatted => decredAmountToString(amount: fee);

  @override
  String get hex => rawHex;

  @override
  Future<void> commit() async {
    // TODO: Submit rawHex using libdcrwallet.
  }
}
