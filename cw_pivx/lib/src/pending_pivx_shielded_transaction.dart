import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/exceptions.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'sapling/sapling_factories.dart' show SaplingTransactionResult;
import 'sapling/sapling_note_storage.dart';

/// Wraps a [SaplingTransactionResult] as a [PendingTransaction] so shielded
/// txs are handled uniformly with transparent ones.
class PendingPivxShieldedTransaction with PendingTransaction {
  PendingPivxShieldedTransaction({
    required this.result,
    required this.electrumClient,
    required int amount,
    required int fee,
    this.noteStorage,
    this.onCommit,
  })  : amount = Money.fromInt(amount, CryptoCurrency.pivx),
        fee = Money.fromInt(fee, CryptoCurrency.pivx);

  final SaplingTransactionResult result;

  final ElectrumClient electrumClient;

  @override
  final Money amount;

  @override
  final Money fee;

  /// Its spent notes are locked before [onCommit] runs.
  final SaplingNoteStorage? noteStorage;

  /// Called after a successful broadcast.
  final Future<void> Function(dynamic)? onCommit;

  // Lock first: commit() swallows bookkeeping errors, and unlocked notes
  // invite a conflicting send.
  Future<void> _lockAndRecord() async {
    if (result.spentNullifiers.isNotEmpty) {
      await noteStorage?.markPendingSpentByNullifiers(
          result.spentNullifiers, result.txId);
    }
    await onCommit?.call(this);
  }

  @override
  String get id => result.txId;

  @override
  String get hex => result.txHex;

  @override
  String get amountFormatted =>
      bitcoinAmountToString(amount: amount.amount.toInt());

  @override
  String get feeFormatted => "$feeFormattedValue PIVX";

  String get feeFormattedValue =>
      bitcoinAmountToString(amount: fee.amount.toInt());

  static String sanitizeBroadcastError(String error) {
    var message = error.trim();
    final lowerMessage = message.toLowerCase();

    const saplingRejections = {
      'bad-txns-sapling-spend-description-invalid':
          'PIVX node rejected the shielded transaction: Sapling spend proof/signature validation failed.',
      'bad-txns-sapling-output-description-invalid':
          'PIVX node rejected the shielded transaction: Sapling output proof validation failed.',
      'bad-txns-sapling-binding-signature-invalid':
          'PIVX node rejected the shielded transaction: Sapling binding signature validation failed.',
      'bad-txns-shielded-requirements-not-met':
          'PIVX node rejected the shielded transaction: Sapling anchor or nullifier requirements were not met.',
      'bad-txns-sapling-requirements-not-met':
          'PIVX node rejected the shielded transaction: Sapling anchor or nullifier requirements were not met.',
      'bad-txns-nullifier-double-spent':
          'PIVX node rejected the shielded transaction: selected shielded note was already spent.',
      'bad-spend-description-nullifiers-duplicate':
          'PIVX node rejected the shielded transaction: duplicate shielded nullifier.',
      'bad-txns-valuebalance-nonzero':
          'PIVX node rejected the shielded transaction: invalid Sapling value balance.',
      'bad-txns-valuebalance-toolarge':
          'PIVX node rejected the shielded transaction: Sapling value balance is too large.',
      'bad-txns-invalid-sapling-act':
          'PIVX node rejected the shielded transaction: Sapling is not active on this chain height.',
      'bad-txns-invalid-sapling':
          'PIVX node rejected the shielded transaction: invalid Sapling transaction form.',
    };

    for (final entry in saplingRejections.entries) {
      if (lowerMessage.contains(entry.key)) {
        return '${entry.value} (${entry.key})';
      }
    }

    message = message
        .replaceAll(RegExp(r'\[[0-9a-fA-F\s]{128,}\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (message.isEmpty) {
      return 'Failed to broadcast shielded transaction';
    }

    const maxLength = 240;
    if (message.length > maxLength) {
      message = '${message.substring(0, maxLength)}...';
    }

    return message;
  }

  @override
  Future<void> commit() async {
    try {
      int? callId;
      final txid = await electrumClient.broadcastTransaction(
        transactionRaw: hex,
        network: null,
        idCallback: (id) => callId = id,
      );

      if (txid.isEmpty) {
        final error =
            callId == null ? '' : electrumClient.getErrorMessage(callId!);
        // No call id: call() returned before sending (offline), nothing left.
        if (error.isEmpty && callId != null) await _reserveUnknownBroadcast();
        final message = sanitizeBroadcastError(error);
        printV('[PendingPivxShieldedTransaction] Broadcast failed: $message');
        throw BitcoinTransactionCommitFailed(errorMessage: message);
      }

      // The node accepted something under another id: unknown, not rejected.
      if (txid.toLowerCase() != id.toLowerCase()) {
        printV('[PendingPivxShieldedTransaction] Broadcast txid mismatch');
        await _reserveUnknownBroadcast();
      }

      // Broadcast done: a bookkeeping failure must not read as a broadcast
      // failure and prompt a double send. The next sync reconciles.
      try {
        await _lockAndRecord();
      } catch (e) {
        printV(
            '[PendingPivxShieldedTransaction] Post-broadcast bookkeeping failed: $e');
      }
    } on BitcoinTransactionCommitFailed {
      rethrow;
    } catch (e) {
      await _reserveUnknownBroadcast();
    }
  }

  // No server verdict (timeout, dropped socket): the tx may already be in the
  // mempool. Reserve its notes as on success so a resend cannot reuse them;
  // pending eviction frees them if the node never sees the tx. A t-to-z spend
  // has no notes and no eviction path, so record nothing for it.
  Future<Never> _reserveUnknownBroadcast() async {
    if (result.spentNullifiers.isEmpty) {
      throw BitcoinTransactionCommitFailed(
        errorMessage: 'Broadcast result unknown. Do not resend until you '
            'verify transaction $id was not accepted.',
      );
    }
    try {
      await _lockAndRecord();
    } catch (e) {
      printV('[PendingPivxShieldedTransaction] Reserving inputs failed: $e');
    }
    throw BitcoinTransactionCommitFailed(
      errorMessage: 'Broadcast result unknown. The funds stay reserved until '
          'the network confirms or drops the transaction. Do not resend.',
    );
  }

  @override
  Future<Map<String, String>> commitUR() async => {};
}
