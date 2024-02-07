import 'package:cw_core/pending_transaction.dart';
import 'package:solana/encoder.dart';

class PendingSolanaTransaction with PendingTransaction {
  final double amount;
  final SignedTx signedTransaction;
  final String destinationAddress;
  final Function sendTransaction;
  final double fee;

  PendingSolanaTransaction({
    required this.fee,
    required this.amount,
    required this.signedTransaction,
    required this.destinationAddress,
    required this.sendTransaction,
  });

  @override
  String get amountFormatted {
    String stringifiedAmount = amount.toString();

    if (stringifiedAmount.toString().length >= 6) {
      stringifiedAmount = stringifiedAmount.substring(0, 6);
    }

    return stringifiedAmount;
  }

  @override
  Future<void> commit() async {
    return await sendTransaction();
  }

  @override
  String get feeFormatted => fee.toString();

  @override
  String get hex => signedTransaction.encode();

  @override
  String get id => '';
}
