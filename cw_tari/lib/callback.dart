import 'dart:ffi';

import 'package:tari/src/generated_bindings_tari.freeze.g.dart';
import 'package:tari/tari.dart';

class CallbackPlaceholders {
  // Placeholder for callback_received_transaction
  static void callbackReceivedTransaction(Pointer<Void> context,
      Pointer<TariPendingInboundTransaction> transaction) {
    print('callbackReceivedTransaction called');
  }

  // Placeholder for callback_received_transaction_reply
  static void callbackReceivedTransactionReply(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    print('callbackReceivedTransactionReply called');
  }

  static NativeCallable<CallbackReceivedTransactionReply>
  get callbackReceivedTransactionReplyPtr =>
      NativeCallable<CallableReceivedTransactionReply>.listener(callbackReceivedTransactionReply);

  // Placeholder for callback_received_finalized_transaction
  static void callbackReceivedFinalizedTransaction(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    print('callbackReceivedFinalizedTransaction called');
  }

  static NativeCallable<CallableReceivedFinalizedTransaction>
  get callbackReceivedFinalizedTransactionPtr =>
      NativeCallable<CallableReceivedFinalizedTransaction>.listener(
          callbackReceivedFinalizedTransaction);

  // Placeholder for callback_transaction_broadcast
  static void callbackTransactionBroadcast(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    print('callbackTransactionBroadcast called');
  }

  static NativeCallable<CallableReceivedTransactionBroadcast>
  get callbackTransactionBroadcastPtr =>
      NativeCallable<CallableReceivedTransactionBroadcast>.listener(
          callbackTransactionBroadcast);

  // Placeholder for callback_transaction_mined
  static void callbackTransactionMined(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    print('callbackTransactionMined called');
  }

  static NativeCallable<CallableReceivedTransactionMined>
  get callbackTransactionMinedPtr =>
      NativeCallable<CallableReceivedTransactionMined>.listener(callbackTransactionMined);

  // Placeholder for callback_transaction_mined_unconfirmed
  static void callbackTransactionMinedUnconfirmed(Pointer<Void> context,
      Pointer<TariCompletedTransaction> transaction, int unconfirmed) {
    print('callbackTransactionMinedUnconfirmed called');
  }

  static NativeCallable<CallableReceivedTransactionMinedUnconfirmed>
  get callbackTransactionMinedUnconfirmedPtr =>
      NativeCallable<CallableReceivedTransactionMinedUnconfirmed>.listener(
          callbackTransactionMinedUnconfirmed);

  // Placeholder for callback_faux_transaction_confirmed
  static void callbackFauxTransactionConfirmed(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    print('callbackFauxTransactionConfirmed called');
  }

  static NativeCallable<CallableFauxTransactionMinedConfirmed>
  get callbackFauxTransactionConfirmedPtr =>
      NativeCallable<CallableFauxTransactionMinedConfirmed>.listener(
          callbackFauxTransactionConfirmed);

  // Placeholder for callback_faux_transaction_unconfirmed
  static void callbackFauxTransactionUnconfirmed(Pointer<Void> context,
      Pointer<TariCompletedTransaction> transaction, int unconfirmed) {
    print('callbackFauxTransactionUnconfirmed called');
  }

  static NativeCallable<CallableFauxTransactionMinedUnconfirmed>
  get callbackFauxTransactionUnconfirmedPtr =>
      NativeCallable<CallableFauxTransactionMinedUnconfirmed>.listener(
          callbackFauxTransactionUnconfirmed);

  // Placeholder for callback_transaction_send_result
  static void callbackTransactionSendResult(Pointer<Void> context, int result,
      Pointer<TariTransactionSendStatus> status) {
    print('callbackTransactionSendResult called');
  }

  static NativeCallable<
      Void Function(Pointer<Void>, UnsignedLongLong,
          Pointer<TariTransactionSendStatus>)> get callbackTransactionSendResultPtr =>
      NativeCallable<CallableTransactionSendResult>.listener(
          callbackTransactionSendResult);

  // Placeholder for callback_transaction_cancellation
  static void callbackTransactionCancellation(Pointer<Void> context,
      Pointer<TariCompletedTransaction> transaction, int cancellation) {
    print('callbackTransactionCancellation called');
  }

  static NativeCallable<
      Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>, Uint64)>
  get callbackTransactionCancellationPtr =>
      NativeCallable<CallableTransactionCancellation>.listener(
          callbackTransactionCancellation);

  // Placeholder for callback_txo_validation_complete
  static void callbackTxoValidationComplete(
      Pointer<Void> context, int txo, int validation) {
    print('callbackTxoValidationComplete called');
  }

  static NativeCallable<Void Function(Pointer<Void>, Uint64, Uint64)>
  get callbackTxoValidationCompletePtr =>
      NativeCallable<CallableTxoValidationComplete>.listener(
          callbackTxoValidationComplete);

  // Placeholder for callback_contacts_liveness_data_updated
  static void callbackContactsLivenessDataUpdated(
      Pointer<Void> context, Pointer<TariContactsLivenessData> data) {
    print('callbackContactsLivenessDataUpdated called');
  }

  static NativeCallable<
      Void Function(Pointer<Void>, Pointer<TariContactsLivenessData>)>
  get callbackContactsLivenessDataUpdatedPtr =>
      NativeCallable<CallableContactsLivenessDataUpdated>.listener(
          callbackContactsLivenessDataUpdated);

  // Placeholder for callback_balance_updated
  static void callbackBalanceUpdated(
      Pointer<Void> context, Pointer<TariBalance> balance) {
    print('callbackBalanceUpdated called');
  }

  static NativeCallable<Void Function(Pointer<Void>, Pointer<TariBalance>)>
  get callbackBalanceUpdatedPtr =>
      NativeCallable<CallableBalanceUpdated>.listener(callbackBalanceUpdated);

  // Placeholder for callback_transaction_validation_complete
  static void callbackTransactionValidationComplete(
      Pointer<Void> context, int transaction, int validation) {
    print('callbackTransactionValidationComplete called');
  }

  static NativeCallable<Void Function(Pointer<Void>, Uint64, Uint64)>
  get callbackTransactionValidationCompletePtr =>
      NativeCallable<CallableTransactionValidationComplete>.listener(
          callbackTransactionValidationComplete);

  // Placeholder for callback_saf_messages_received
  static void callbackSafMessagesReceived(Pointer<Void> context) {
    print('callbackSafMessagesReceived called');
  }

  static NativeCallable<Void Function(Pointer<Void>)>
  get callbackSafMessagesReceivedPtr =>
      NativeCallable<CallableSafMessagesReceived>.listener(
          callbackSafMessagesReceived);

  // Placeholder for callback_connectivity_status
  static void callbackConnectivityStatus(Pointer<Void> context, int status) {
    // 0: Connecting, 1: Online, 2: Offline
    switch (status) {
      case 0:
        print('Connecting to base node...');
        break;
      case 1:
        print('Connected to base node successfully');
        break;
      case 2:
        print('Connection to base node offline');
        break;
    }
  }

  static NativeCallable<Void Function(Pointer<Void>, Uint64)>
  get callbackConnectivityStatusPtr =>
      NativeCallable<CallableConnectivityStatus>.listener(
          callbackConnectivityStatus);

  // Placeholder for callback_wallet_scanned_height
  static void callbackWalletScannedHeight(Pointer<Void> context, int height) {
    print('callbackWalletScannedHeight called');
  }

  static NativeCallable<Void Function(Pointer<Void>, Uint64)>
  get callbackWalletScannedHeightPtr =>
      NativeCallable<CallableWalletScannedHeight>.listener(
          callbackWalletScannedHeight);

  // Placeholder for callback_base_node_state
  static void callbackBaseNodeState(
      Pointer<Void> context, Pointer<TariBaseNodeState> state) {
    print('callbackBaseNodeState called');
  }

  static NativeCallable<Void Function(Pointer<Void>, Pointer<TariBaseNodeState>)>
  get callbackBaseNodeStatePtr =>
      NativeCallable<CallableBaseNodeState>.listener(callbackBaseNodeState);
}
