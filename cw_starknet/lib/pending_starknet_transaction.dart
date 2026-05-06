import 'package:cw_core/format_fixed.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_starknet/starknet_balance.dart';

class PendingStarknetTransaction with PendingTransaction {
  PendingStarknetTransaction({
    required this.amountWei,
    required this.amountDecimals,
    required this.amountSymbol,
    required this.destinationAddress,
    required this.sendTransaction,
    required this.feeWei,
    this.transactionHash = '',
    this.buildUnsignedTransactionUr,
    this.onCommitted,
  });

  final String amountWei;
  final int amountDecimals;
  final String amountSymbol;
  final String transactionHash;
  final String destinationAddress;
  final Future<String> Function() sendTransaction;
  final String feeWei;
  final Future<Map<String, String>> Function()? buildUnsignedTransactionUr;
  final Future<void> Function(String txHash)? onCommitted;
  String? _txHash;

  @override
  String get amountFormatted => truncateDecimalString(
        formatFixed(BigInt.parse(amountWei), amountDecimals, fractionalDigits: amountDecimals),
      );

  @override
  Future<void> commit() async {
    _txHash = await sendTransaction();
    final txHash = _txHash;
    if (txHash != null) {
      await onCommitted?.call(txHash);
    }
  }

  @override
  String get feeFormatted => '$feeFormattedValue STRK';

  @override
  String get feeFormattedValue =>
      truncateDecimalString(formatFixed(BigInt.parse(feeWei), 18, fractionalDigits: 18));

  @override
  String get hex => transactionHash;

  @override
  String get id => _txHash ?? transactionHash;

  @override
  bool shouldCommitUR() => buildUnsignedTransactionUr != null;

  @override
  Future<Map<String, String>> commitUR() async =>
      await buildUnsignedTransactionUr?.call() ??
      (throw UnsupportedError(
          'Offline UR signing is not configured for this Starknet transaction.'));
}
