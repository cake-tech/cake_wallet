import 'dart:typed_data';

import 'package:cw_core/pending_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class PendingEthereumTransaction with PendingTransaction {
  final Function sendTransaction;
  final Uint8List signedTransaction;
  final BigInt fee;
  final String amount;

  PendingEthereumTransaction({
    required this.sendTransaction,
    required this.signedTransaction,
    required this.fee,
    required this.amount,
  });

  @override
  String get amountFormatted =>
      EtherAmount.inWei(BigInt.parse(amount)).getValueInUnit(EtherUnit.ether).toString();

  @override
  Future<void> commit() async => await sendTransaction();

  @override
  String get feeFormatted => EtherAmount.inWei(fee).getValueInUnit(EtherUnit.ether).toString();

  @override
  String get hex => bytesToHex(signedTransaction, include0x: true);

  @override
  String get id => '';
}
