import 'dart:typed_data';
import 'package:cw_evm/pending_evm_chain_transaction.dart';

class PendingPolygonTransaction extends PendingEVMChainTransaction {
  PendingPolygonTransaction({
    required Function sendTransaction,
    required Uint8List signedTransaction,
    required BigInt fee,
    required String amount,
    required int exponent,
  }) : super(
          amount: amount,
          sendTransaction: sendTransaction,
          signedTransaction: signedTransaction,
          fee: fee,
          exponent: exponent,
        );
}
