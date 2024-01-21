import 'package:cw_core/pending_transaction.dart';

class PendingSolanaTransaction with PendingTransaction {
  final double amount;
  final String signature;
  final String destinationAddress;

  PendingSolanaTransaction({
    required this.amount,
    required this.signature,
    required this.destinationAddress,
  });

  @override
  String get amountFormatted {
    String stringifiedAmount = amount.toString();

    if (stringifiedAmount.toString().length >= 6) {
      stringifiedAmount = stringifiedAmount.substring(0, 6);
    }

    return stringifiedAmount;
  }

  @override
  Future<void> commit() async {}

  @override
  String get feeFormatted {
    return '';
  }

  @override
  String get hex => signature;

  @override
  String get id => '';
}
