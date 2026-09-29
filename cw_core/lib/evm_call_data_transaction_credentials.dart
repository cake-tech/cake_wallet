import 'package:cw_core/amount/money.dart';
import 'package:cw_core/transaction_priority.dart';

/// A raw EVM call with a provider-supplied gas floor. The wallet still
/// estimates fees, checks balances and constructs/signs the transaction.
class EvmCallDataTransactionCredentials {
  const EvmCallDataTransactionCredentials({
    required this.to,
    required this.data,
    required this.value,
    required this.priority,
    required this.gasLimit,
    this.sourceTokenAddress,
    this.sourceTokenAmount,
    this.useBlinkProtection = true,
  });

  final String to;
  final String data;
  final Money value;
  final TransactionPriority? priority;
  final int gasLimit;
  final String? sourceTokenAddress;
  final BigInt? sourceTokenAmount;
  final bool useBlinkProtection;
}
