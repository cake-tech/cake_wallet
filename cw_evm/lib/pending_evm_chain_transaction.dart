import 'dart:math';
import 'dart:typed_data';

import 'package:cw_core/pending_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:hex/hex.dart' as Hex;

class PendingEVMChainTransaction with PendingTransaction {
  final Function sendTransaction;
  final Uint8List signedTransaction;
  final BigInt fee;
  final String amount;
  final int exponent;

  PendingEVMChainTransaction({
    required this.sendTransaction,
    required this.signedTransaction,
    required this.fee,
    required this.amount,
    required this.exponent,
  });

  @override
  String get amountFormatted {
    final _amount = (BigInt.parse(amount) / BigInt.from(pow(10, exponent))).toString();
    return _amount.substring(0, min(10, _amount.length));
  }

  @override
  Future<void> commit() async => await sendTransaction();

  @override
  String get feeFormatted {
    final _fee = (fee / BigInt.from(pow(10, 18))).toString();
    return _fee.substring(0, min(10, _fee.length));
  }

  @override
  String get hex => bytesToHex(signedTransaction, include0x: true);

  @override
  String get id {
    final String eip1559Hex = '0x02${hex.substring(2)}';
    final Uint8List bytes = Uint8List.fromList(Hex.HEX.decode(eip1559Hex.substring(2)));

    var txid = keccak256(bytes);

    return '0x${Hex.HEX.encode(txid)}';
  }
  
  @override
  Future<String?> commitUR() {
    throw UnimplementedError();
  }
}
