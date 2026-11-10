import 'package:cw_core/amount/money.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/transaction_priority.dart';

class PendingMinotariTransaction with PendingTransaction {
  PendingMinotariTransaction({
    required this.amount,
    required this.fee,
    required this.send,
    required this.isFeeEstimate,
  });

  @override
  final Money amount;

  @override
  final Money fee;

  final Future<void> Function() send;

  /// cw builds every send at a fixed fee rate, so only a send-all's quote is exact.
  @override
  final bool isFeeEstimate;

  // shortcut: the bridge drops send_transaction's SendResultDto, so the recorded transaction id
  // is unknown here; the scanner reports the send by id. Upgrade once the send stream carries it.
  @override
  String get id => '';

  @override
  String get amountFormatted => amount.toStringWithSymbol();

  @override
  String get hex => '';

  @override
  Future<void> commit() => send();

  @override
  Future<Map<String, String>> commitUR() =>
      throw UnsupportedError('UR is not supported for Minotari');
}

class MinotariTransactionCredentials {
  final List<OutputInfo> outputs;
  final TransactionPriority? priority;

  MinotariTransactionCredentials(this.outputs, {this.priority});
}
