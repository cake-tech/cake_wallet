import 'package:cw_core/amount/money.dart';

class SolanaTransactionModel {
  final String id;

  final String from;

  final String to;

  final Money amount;

  final bool isOutgoingTx;

  // The Program ID of this transaction, e.g, System Program, Token Program...
  final String programId;

  final DateTime blockTime;

  final Money fee;

  SolanaTransactionModel({
    required this.id,
    required this.to,
    required this.from,
    required this.amount,
    required this.programId,
    required int blockTimeInInt,
    this.isOutgoingTx = false,
    required this.fee,
  }) : blockTime = DateTime.fromMillisecondsSinceEpoch(blockTimeInInt * 1000);
}
