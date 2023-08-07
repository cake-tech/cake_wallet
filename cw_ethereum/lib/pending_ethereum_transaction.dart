import 'dart:math';
import 'dart:typed_data';

import 'package:cw_core/pending_transaction.dart';
import 'package:web3dart/crypto.dart';

class PendingEthereumTransaction with PendingTransaction {
  final Function sendTransaction;
  final Uint8List signedTransaction;
  final BigInt fee;
  final String amount;
  final int exponent;

  PendingEthereumTransaction({
    required this.sendTransaction,
    required this.signedTransaction,
    required this.fee,
    required this.amount,
    required this.exponent,
  });

  @override
  String get amountFormatted => (BigInt.parse(amount) / BigInt.from(pow(10, exponent))).toString();

  @override
  Future<void> commit() async => await sendTransaction();

  @override
  String get feeFormatted => (fee / BigInt.from(pow(10, 18))).toString();

  @override
  String get hex => bytesToHex(signedTransaction, include0x: true);

  @override
  String get id => '';
}
