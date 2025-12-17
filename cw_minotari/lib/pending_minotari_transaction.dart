import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/output_info.dart';

class PendingMinotariTransaction with PendingTransaction {
  final String id;
  final int amount;
  final int fee;
  final String recipientAddress;

  PendingMinotariTransaction({
    required this.id,
    required this.amount,
    required this.fee,
    required this.recipientAddress,
  });

  @override
  String get amountFormatted {
    // Convert microTari to XTM (6 decimal places)
    final wholePart = amount ~/ 1000000;
    final fractionalPart = amount % 1000000;
    return '$wholePart.${fractionalPart.toString().padLeft(6, '0')} XTM';
  }

  @override
  String get feeFormatted {
    // Convert microTari to XTM (6 decimal places)
    final wholePart = fee ~/ 1000000;
    final fractionalPart = fee % 1000000;
    return '$wholePart.${fractionalPart.toString().padLeft(6, '0')} XTM';
  }

  @override
  String get feeFormattedValue => feeFormatted;

  @override
  String get hex => id; // Stub - return transaction ID as hex

  @override
  Future<void> commit() async {
    // TODO: Implement transaction commitment via FFI
    throw UnimplementedError('Transaction commit not yet implemented');
  }

  @override
  Future<Map<String, String>> commitUR() async {
    // UR (Uniform Resources) not supported for Minotari
    throw UnimplementedError('UR not supported for Minotari');
  }
}

class MinotariTransactionCredentials {
  final List<OutputInfo> outputs;

  MinotariTransactionCredentials(this.outputs);
}
