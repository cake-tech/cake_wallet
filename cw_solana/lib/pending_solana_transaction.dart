import 'package:cw_core/amount/money.dart';
import 'package:cw_core/pending_transaction.dart';

class PendingSolanaTransaction with PendingTransaction {
  final String serializedTransaction;
  final String destinationAddress;
  final Function sendTransaction;
  String? _sig;

  PendingSolanaTransaction({
    required this.fee,
    required this.amount,
    required this.serializedTransaction,
    required this.destinationAddress,
    required this.sendTransaction,
  });

  @override
  final Money amount;

  @override
  final Money fee;

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
    _sig = await sendTransaction();
  }

  @override
  String get hex => serializedTransaction;

  @override
  String get id => _sig ?? '';

  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError();
  }
}
