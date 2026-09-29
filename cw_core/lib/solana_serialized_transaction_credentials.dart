import 'package:cw_core/amount/money.dart';

/// A supplied Solana transaction for the wallet's normal prepare/commit flow.
/// The caller owns instruction semantics; the wallet preserves the message.
final class SolanaSerializedTransactionCredentials {
  const SolanaSerializedTransactionCredentials(
      {required this.transactionBase58, required this.amount, required this.destinationAddress});
  final String transactionBase58;
  final Money amount;
  final String destinationAddress;
}
