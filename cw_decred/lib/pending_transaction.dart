import 'package:cw_core/amount/money.dart';
import 'package:cw_core/pending_transaction.dart';

class DecredPendingTransaction with PendingTransaction {
  DecredPendingTransaction({
    required this.txId,
    required this.amount,
    required this.fee,
    required this.rawHex,
    required this.send,
  });

  final Money amount;
  final Money fee;
  final String txId;
  final String rawHex;
  final Future<void> Function() send;

  @override
  String get id => txId;

  @override
  String get amountFormatted => amount.toString();

  @override
  String get hex => rawHex;

  @override
  Future<void> commit() => send();

  @override
  Future<Map<String, String>> commitUR() => throw UnimplementedError();
}
