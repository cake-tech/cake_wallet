import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/transaction_info.dart';

/// cw's status of a Minotari transaction (its DisplayedTransactionStatus name), translated.
String minotariTransactionStatus(TransactionInfo tx) {
  final status = tx.additionalInfo['status'] as String? ?? '';
  return switch (status) {
    'pending' => S.current.tx_status_pending,
    'unconfirmed' => S.current.tx_status_unconfirmed,
    'confirmed' => S.current.tx_status_confirmed,
    'cancelled' => S.current.tx_status_cancelled,
    'reorganized' => S.current.tx_status_reorganized,
    'rejected' => S.current.tx_status_rejected,
    'locked' => S.current.tx_status_locked,
    _ => status,
  };
}

/// A Minotari transaction that won't confirm as it is (rejected, which includes an abandoned
/// send, cancelled or reorganized); the history shows its status so it can't pass for sent.
bool isMinotariFailedTransaction(TransactionInfo tx) =>
    const {'rejected', 'cancelled', 'reorganized'}.contains(tx.additionalInfo['status']);

/// A Minotari send the node had not accepted when it was made, while cw still has it pending.
/// It is recorded and rebroadcast, so it must not be sent again.
bool isMinotariSendNotAccepted(TransactionInfo tx) =>
    tx.additionalInfo['notAcceptedByNode'] is String;

/// What the user should know about a Minotari send: that the node has not accepted it yet (and
/// the node's reason), or that the user abandoned it and it was mined after all.
String? minotariSendWarning(TransactionInfo tx) {
  final reason = tx.additionalInfo['notAcceptedByNode'] as String?;
  if (reason != null) {
    return reason.isEmpty
        ? S.current.minotari_not_accepted_by_node
        : '${S.current.minotari_not_accepted_by_node}: $reason';
  }
  if (tx.additionalInfo['minedAfterAbandon'] == true) return S.current.minotari_mined_after_abandon;
  return null;
}
