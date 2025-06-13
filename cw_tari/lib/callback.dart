import 'dart:ffi';

import 'package:tari/src/generated_bindings_tari.freeze.g.dart';
import 'package:ffi/ffi.dart';
import 'package:tari/ffi.dart';

class CallbackPlaceholders {
  static int _chainTipHeight = 0;
  static int _scannedHeight = 0;
  static int get chainTipHeight => _chainTipHeight;
  static int get scannedHeight => _scannedHeight;
  // Placeholder for callback_received_transaction
  static void callbackReceivedTransaction(Pointer<Void> context,
      Pointer<TariPendingInboundTransaction> transaction) {
    // print('callbackReceivedTransaction called');
  }

  // Placeholder for callback_received_transaction_reply
  static void callbackReceivedTransactionReply(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    // print('callbackReceivedTransactionReply called');
  }

  static Pointer<
      NativeFunction<
          Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>)>>
  get callbackReceivedTransactionReplyPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>)>(
      callbackReceivedTransactionReply);

  // Placeholder for callback_received_finalized_transaction
  static void callbackReceivedFinalizedTransaction(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    // print('callbackReceivedFinalizedTransaction called');
  }

  static Pointer<
      NativeFunction<
          Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>)>>
  get callbackReceivedFinalizedTransactionPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>)>(
      callbackReceivedFinalizedTransaction);

  // Placeholder for callback_transaction_broadcast
  static void callbackTransactionBroadcast(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    // print('callbackTransactionBroadcast called');
  }

  static Pointer<
      NativeFunction<
          Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>)>>
  get callbackTransactionBroadcastPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>,
          Pointer<TariCompletedTransaction>)>(callbackTransactionBroadcast);

  // Placeholder for callback_transaction_mined
  static void callbackTransactionMined(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    // print('callbackTransactionMined called');
  }

  static Pointer<
      NativeFunction<
          Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>)>>
  get callbackTransactionMinedPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>,
          Pointer<TariCompletedTransaction>)>(callbackTransactionMined);

  // Placeholder for callback_transaction_mined_unconfirmed
  static void callbackTransactionMinedUnconfirmed(Pointer<Void> context,
      Pointer<TariCompletedTransaction> transaction, int unconfirmed) {
    // print('callbackTransactionMinedUnconfirmed called');
  }

  static Pointer<
      NativeFunction<
          Void Function(
              Pointer<Void>, Pointer<TariCompletedTransaction>, Uint64)>>
  get callbackTransactionMinedUnconfirmedPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>,
          Uint64)>(callbackTransactionMinedUnconfirmed);

  // Placeholder for callback_faux_transaction_confirmed
  static void callbackFauxTransactionConfirmed(
      Pointer<Void> context, Pointer<TariCompletedTransaction> transaction) {
    // print('callbackFauxTransactionConfirmed called');
  }

  static Pointer<
      NativeFunction<
          Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>)>>
  get callbackFauxTransactionConfirmedPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>)>(
      callbackFauxTransactionConfirmed);

  // Placeholder for callback_faux_transaction_unconfirmed
  static void callbackFauxTransactionUnconfirmed(Pointer<Void> context,
      Pointer<TariCompletedTransaction> transaction, int unconfirmed) {
    // print('callbackFauxTransactionUnconfirmed called');
  }

  static Pointer<
      NativeFunction<
          Void Function(
              Pointer<Void>, Pointer<TariCompletedTransaction>, Uint64)>>
  get callbackFauxTransactionUnconfirmedPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>,
          Uint64)>(callbackFauxTransactionUnconfirmed);

  // Placeholder for callback_transaction_send_result
  static void callbackTransactionSendResult(Pointer<Void> context, int result,
      Pointer<TariTransactionSendStatus> status) {
    print('callbackTransactionSendResult called');
  }

  static Pointer<
      NativeFunction<
          Void Function(Pointer<Void>, UnsignedLongLong,
              Pointer<TariTransactionSendStatus>)>>
  get callbackTransactionSendResultPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>, UnsignedLongLong,
          Pointer<TariTransactionSendStatus>)>(
      callbackTransactionSendResult);

  // Placeholder for callback_transaction_cancellation
  static void callbackTransactionCancellation(Pointer<Void> context,
      Pointer<TariCompletedTransaction> transaction, int cancellation) {
    print('callbackTransactionCancellation called');
  }

  static Pointer<
      NativeFunction<
          Void Function(
              Pointer<Void>, Pointer<TariCompletedTransaction>, Uint64)>>
  get callbackTransactionCancellationPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>, Pointer<TariCompletedTransaction>,
          Uint64)>(callbackTransactionCancellation);

  // Placeholder for callback_txo_validation_complete
  static void callbackTxoValidationComplete(
      Pointer<Void> context, int txo, int validation) {
    print('callbackTxoValidationComplete called $txo $validation');
  }

  static Pointer<NativeFunction<Void Function(Pointer<Void>, Uint64, Uint64)>>
  get callbackTxoValidationCompletePtr =>
      Pointer.fromFunction<Void Function(Pointer<Void>, Uint64, Uint64)>(
          callbackTxoValidationComplete);

  // Placeholder for callback_contacts_liveness_data_updated
  static void callbackContactsLivenessDataUpdated(
      Pointer<Void> context, Pointer<TariContactsLivenessData> data) {
    // print('callbackContactsLivenessDataUpdated called');
  }

  static Pointer<
      NativeFunction<
          Void Function(Pointer<Void>, Pointer<TariContactsLivenessData>)>>
  get callbackContactsLivenessDataUpdatedPtr => Pointer.fromFunction<
      Void Function(Pointer<Void>, Pointer<TariContactsLivenessData>)>(
      callbackContactsLivenessDataUpdated);

  // Placeholder for callback_balance_updated
  static void callbackBalanceUpdated(
      Pointer<Void> context, Pointer<TariBalance> balance) {
    // print('callbackBalanceUpdated called');
  }

  static Pointer<
      NativeFunction<Void Function(Pointer<Void>, Pointer<TariBalance>)>>
  get callbackBalanceUpdatedPtr => Pointer.fromFunction<
      Void Function(
          Pointer<Void>, Pointer<TariBalance>)>(callbackBalanceUpdated);

  // Placeholder for callback_transaction_validation_complete
  static void callbackTransactionValidationComplete(
      Pointer<Void> context, int transaction, int validation) {
    // print(
    //     'callbackTransactionValidationComplete called $transaction $validation');
  }

  static Pointer<NativeFunction<Void Function(Pointer<Void>, Uint64, Uint64)>>
  get callbackTransactionValidationCompletePtr =>
      Pointer.fromFunction<Void Function(Pointer<Void>, Uint64, Uint64)>(
          callbackTransactionValidationComplete);

  // Placeholder for callback_saf_messages_received
  static void callbackSafMessagesReceived(Pointer<Void> context) {
    // print('callbackSafMessagesReceived called');
  }

  static Pointer<NativeFunction<Void Function(Pointer<Void>)>>
  get callbackSafMessagesReceivedPtr =>
      Pointer.fromFunction<Void Function(Pointer<Void>)>(
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

  static Pointer<NativeFunction<Void Function(Pointer<Void>, Uint64)>>
  get callbackConnectivityStatusPtr =>
      Pointer.fromFunction<Void Function(Pointer<Void>, Uint64)>(
          callbackConnectivityStatus);

  // Placeholder for callback_wallet_scanned_height
  static void callbackWalletScannedHeight(Pointer<Void> context, int height) {
    print('Scanned height: $height / ${_chainTipHeight}');
    _scannedHeight = height;
  }

  static Pointer<NativeFunction<Void Function(Pointer<Void>, Uint64)>>
  get callbackWalletScannedHeightPtr =>
      Pointer.fromFunction<Void Function(Pointer<Void>, Uint64)>(
          callbackWalletScannedHeight);

  // Placeholder for callback_base_node_state
  static void callbackBaseNodeState(
      Pointer<Void> context, Pointer<TariBaseNodeState> state) {
    final errorPtr = malloc<Int>();
    _chainTipHeight = lib.basenode_state_get_height_of_the_longest_chain(state, errorPtr);
    print('Current chain tip height: $_chainTipHeight');
  }

  static Pointer<
      NativeFunction<
          Void Function(Pointer<Void>, Pointer<TariBaseNodeState>)>>
  get callbackBaseNodeStatePtr => Pointer.fromFunction<
      Void Function(Pointer<Void>,
          Pointer<TariBaseNodeState>)>(callbackBaseNodeState);
}
