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
  String get amountFormatted {
    final _amount = BigInt.parse(amount) / BigInt.from(pow(10, exponent));
    return _amount.toStringAsFixed(min(15, _amount.toString().length));
  }

  @override
  Future<void> commit() async => await sendTransaction();

  @override
  String get feeFormatted {
    final _fee = fee / BigInt.from(pow(10, 18));
    return _fee.toStringAsFixed(min(15, _fee.toString().length));
  }

  @override
  String get hex => bytesToHex(signedTransaction, include0x: true);

  @override
  String get id => '';
}
