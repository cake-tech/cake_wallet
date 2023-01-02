import 'dart:ffi';

import 'package:cw_wownero/api/structs/pending_transaction.dart';
import 'package:cw_wownero/api/structs/ut8_box.dart';
import 'package:ffi/ffi.dart';

typedef wow_create_14_word_wallet = Int8 Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32, Pointer<Utf8>);

typedef wow_create_25_word_wallet = Int8 Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32, Pointer<Utf8>);

typedef wow_restore_wallet_from_14_word_seed = Int8 Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32, Pointer<Utf8>);

typedef wow_restore_wallet_from_25_word_seed = Int8 Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32, Pointer<Utf8>);

typedef wow_restore_wallet_from_keys = Int8 Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Int32,
    Int64,
    Pointer<Utf8>);

typedef wow_is_wallet_exist = Int8 Function(Pointer<Utf8>);

typedef wow_load_wallet = Int8 Function(Pointer<Utf8>, Pointer<Utf8>, Int8);

typedef wow_error_string = Pointer<Utf8> Function();

typedef wow_get_filename = Pointer<Utf8> Function();

typedef wow_get_seed = Pointer<Utf8> Function();

typedef wow_get_address = Pointer<Utf8> Function(Int32, Int32);

typedef wow_get_full_balance = Int64 Function(Int32);

typedef wow_get_unlocked_balance = Int64 Function(Int32);

typedef wow_get_current_height = Int64 Function();

typedef wow_get_node_height = Int64 Function();

typedef wow_get_seed_height = Int64 Function(Pointer<Utf8>);

typedef wow_is_connected = Int8 Function();

typedef wow_setup_node = Int8 Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int8, Int8, Pointer<Utf8>);

typedef wow_start_refresh = Void Function();

typedef wow_connect_to_node = Int8 Function();

typedef wow_set_refresh_from_block_height = Void Function(Int64);

typedef wow_set_recovering_from_seed = Void Function(Int8);

typedef wow_store_c = Void Function(Pointer<Utf8>);

typedef wow_set_password = Int8 Function(
    Pointer<Utf8> password, Pointer<Utf8Box> error);

typedef wow_set_listener = Void Function();

typedef wow_get_syncing_height = Int64 Function();

typedef wow_is_needed_to_refresh = Int8 Function();

typedef wow_is_new_transaction_exist = Int8 Function();

typedef wow_subaddress_size = Int32 Function();

typedef wow_subaddress_refresh = Void Function(Int32);

typedef wow_subaddress_get_all = Pointer<Int64> Function();

typedef wow_subaddress_add_new = Void Function(
    Int32 accountIndex, Pointer<Utf8> label);

typedef wow_subaddress_set_label = Void Function(
    Int32 accountIndex, Int32 addressIndex, Pointer<Utf8> label);

typedef wow_account_size = Int32 Function();

typedef wow_account_refresh = Void Function();

typedef wow_account_get_all = Pointer<Int64> Function();

typedef wow_account_add_new = Void Function(Pointer<Utf8> label);

typedef wow_account_set_label = Void Function(
    Int32 accountIndex, Pointer<Utf8> label);

typedef wow_transactions_refresh = Void Function();

typedef wow_get_tx_key = Pointer<Utf8> Function(Pointer<Utf8> txId);

typedef wow_transactions_count = Int64 Function();

typedef wow_transactions_get_all = Pointer<Int64> Function();

typedef wow_transaction_create = Int8 Function(
    Pointer<Utf8> address,
    Pointer<Utf8> paymentId,
    Pointer<Utf8> amount,
    Int8 priorityRaw,
    Int32 subaddrAccount,
    Pointer<Utf8Box> error,
    Pointer<PendingTransactionRaw> pendingTransaction);

typedef wow_transaction_create_mult_dest = Int8 Function(
    Pointer<Pointer<Utf8>> addresses,
    Pointer<Utf8> paymentId,
    Pointer<Pointer<Utf8>> amounts,
    Int32 size,
    Int8 priorityRaw,
    Int32 subaddrAccount,
    Pointer<Utf8Box> error,
    Pointer<PendingTransactionRaw> pendingTransaction);

typedef wow_transaction_commit = Int8 Function(
    Pointer<PendingTransactionRaw>, Pointer<Utf8Box>);

typedef wow_secret_view_key = Pointer<Utf8> Function();

typedef wow_public_view_key = Pointer<Utf8> Function();

typedef wow_secret_spend_key = Pointer<Utf8> Function();

typedef wow_public_spend_key = Pointer<Utf8> Function();

typedef wow_close_current_wallet = Void Function();

typedef wow_on_startup = Void Function();

typedef wow_rescan_blockchain = Void Function();

typedef wow_get_subaddress_label = Pointer<Utf8> Function(
    Int32 accountIndex, Int32 addressIndex);

typedef wow_validate_address = Int8 Function(Pointer<Utf8> address);
