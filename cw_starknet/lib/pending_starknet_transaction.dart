import 'package:cw_core/pending_transaction.dart';

class PendingStarknetTransaction with PendingTransaction {
  final double amount;
  final String transactionHash;
  final String destinationAddress;
  final Future<String> Function() sendTransaction;
  final double fee;
  String? _txHash;

  PendingStarknetTransaction({
    required this.fee,
    required this.amount,
    required this.transactionHash,
    required this.destinationAddress,
    required this.sendTransaction,
  });

  @override
  String get amountFormatted {
    String stringifiedAmount = amount.toString();

    if (stringifiedAmount.length >= 12) {
      stringifiedAmount = stringifiedAmount.substring(0, 12);
    }

    return stringifiedAmount;
  }

  @override
  Future<void> commit() async {
    _txHash = await sendTransaction();
  }

  @override
  String get feeFormatted => "$feeFormattedValue STRK";

  @override
  String get feeFormattedValue => fee.toString();

  @override
  String get hex => transactionHash;

  @override
  String get id => _txHash ?? '';

  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError();
  }
}
