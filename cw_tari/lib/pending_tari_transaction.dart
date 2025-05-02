import 'dart:math';

import 'package:cw_core/pending_transaction.dart';

class PendingTariTransaction with PendingTransaction {
  final Function sendTransaction;
  final BigInt fee;
  final BigInt amount;
  final int exponent;

  PendingTariTransaction({
    required this.sendTransaction,
    required this.fee,
    required this.amount,
    required this.exponent,
  });

  @override
  String get amountFormatted {
    final amountFmt = (amount / BigInt.from(pow(10, exponent))).toString();
    return amountFmt.substring(0, min(10, amountFmt.length));
  }

  @override
  Future<void> commit() async => await sendTransaction();

  @override
  String get feeFormatted {
    final feeFmt = (fee / BigInt.from(pow(10, 18))).toString();
    return feeFmt.substring(0, min(10, feeFmt.length));
  }

  @override
  String get hex => ""; // ToDo

  @override
  String get id => "0"; // ToDo
  
  @override
  Future<String?> commitUR() => throw UnimplementedError();
}
