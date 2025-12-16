import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/pending_transaction.dart';

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
  Future<void> commit() async {
    // TODO: Implement transaction commitment via FFI
    throw UnimplementedError('Transaction commit not yet implemented');
  }
}

class MinotariTransactionCredentials {
  final List<OutputInfo> outputs;

  MinotariTransactionCredentials(this.outputs);
}

class OutputInfo {
  final String? fiatAmount;
  final String? cryptoAmount;
  final String? address;
  final String? note;
  final bool? sendAll;
  final String? extractedAddress;
  final bool? isParsedAddress;
  final String? formattedCryptoAmount;

  OutputInfo({
    this.fiatAmount,
    this.cryptoAmount,
    this.address,
    this.note,
    this.sendAll,
    this.extractedAddress,
    this.isParsedAddress,
    this.formattedCryptoAmount,
  });
}
