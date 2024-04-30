import 'dart:ffi';

import 'package:cw_monero/api/convert_utf8_to_string.dart';
import 'package:cw_monero/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_monero/api/monero_api.dart';
import 'package:cw_monero/api/monero_output.dart';
import 'package:cw_monero/api/signatures.dart';
import 'package:cw_monero/api/structs/pending_transaction.dart';
import 'package:cw_monero/api/structs/transaction_info_row.dart';
import 'package:cw_monero/api/structs/ut8_box.dart';
import 'package:cw_monero/api/types.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

final transactionsRefreshNative = moneroApi
    .lookup<NativeFunction<transactions_refresh>>('transactions_refresh')
    .asFunction<TransactionsRefresh>();

final transactionsCountNative = moneroApi
    .lookup<NativeFunction<transactions_count>>('transactions_count')
    .asFunction<TransactionsCount>();

final transactionsGetAllNative = moneroApi
    .lookup<NativeFunction<transactions_get_all>>('transactions_get_all')
    .asFunction<TransactionsGetAll>();

final transactionCreateNative = moneroApi
    .lookup<NativeFunction<transaction_create>>('transaction_create')
    .asFunction<TransactionCreate>();

final transactionCreateMultDestNative = moneroApi
    .lookup<NativeFunction<transaction_create_mult_dest>>('transaction_create_mult_dest')
    .asFunction<TransactionCreateMultDest>();

final transactionCommitNative = moneroApi
    .lookup<NativeFunction<transaction_commit>>('transaction_commit')
    .asFunction<TransactionCommit>();

final getTxKeyNative =
    moneroApi.lookup<NativeFunction<get_tx_key>>('get_tx_key').asFunction<GetTxKey>();

final getTransactionNative = moneroApi
    .lookup<NativeFunction<get_transaction>>('get_transaction')
    .asFunction<GetTransaction>();

String getTxKey(String txId) {
  final txIdPointer = txId.toNativeUtf8();
  final keyPointer = getTxKeyNative(txIdPointer);

  calloc.free(txIdPointer);

  if (keyPointer != null) {
    return convertUTF8ToString(pointer: keyPointer);
  }

  return '';
}

void refreshTransactions() => transactionsRefreshNative();

int countOfTransactions() => transactionsCountNative();

List<TransactionInfoRow> getAllTransactions() {
  final size = transactionsCountNative();
  final transactionsPointer = transactionsGetAllNative();
  final transactionsAddresses = transactionsPointer.asTypedList(size);

  return transactionsAddresses
      .map((addr) => Pointer<TransactionInfoRow>.fromAddress(addr).ref)
      .toList();
}

TransactionInfoRow getTransaction(String txId) {
  final txIdPointer = txId.toNativeUtf8();
  return getTransactionNative(txIdPointer).ref;
}

PendingTransactionDescription createTransactionSync(
    {required String address,
    required String paymentId,
    required int priorityRaw,
    String? amount,
    int accountIndex = 0,
    List<String> preferredInputs = const []}) {
  final addressPointer = address.toNativeUtf8();
  final paymentIdPointer = paymentId.toNativeUtf8();
  final amountPointer = amount != null ? amount.toNativeUtf8() : nullptr;

  final int preferredInputsSize = preferredInputs.length;
  final List<Pointer<Utf8>> preferredInputsPointers =
      preferredInputs.map((output) => output.toNativeUtf8()).toList();
  final Pointer<Pointer<Utf8>> preferredInputsPointerPointer = calloc(preferredInputsSize);

  for (int i = 0; i < preferredInputsSize; i++) {
    preferredInputsPointerPointer[i] = preferredInputsPointers[i];
  }

  final errorMessagePointer = calloc<Utf8Box>();
  final pendingTransactionRawPointer = calloc<PendingTransactionRaw>();
  final created = transactionCreateNative(
          addressPointer,
          paymentIdPointer,
          amountPointer,
          priorityRaw,
          accountIndex,
          preferredInputsPointerPointer,
          preferredInputsSize,
          errorMessagePointer,
          pendingTransactionRawPointer) !=
      0;

  calloc.free(preferredInputsPointerPointer);

  preferredInputsPointers.forEach((element) => calloc.free(element));

  calloc.free(addressPointer);
  calloc.free(paymentIdPointer);

  if (amountPointer != nullptr) {
    calloc.free(amountPointer);
  }

  if (!created) {
    final message = errorMessagePointer.ref.getValue();
    calloc.free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }

  return PendingTransactionDescription(
      amount: pendingTransactionRawPointer.ref.amount,
      fee: pendingTransactionRawPointer.ref.fee,
      hash: pendingTransactionRawPointer.ref.getHash(),
      hex: pendingTransactionRawPointer.ref.getHex(),
      txKey: pendingTransactionRawPointer.ref.getKey(),
      pointerAddress: pendingTransactionRawPointer.address);
}

PendingTransactionDescription createTransactionMultDestSync(
    {required List<MoneroOutput> outputs,
    required String paymentId,
    required int priorityRaw,
    int accountIndex = 0,
    List<String> preferredInputs = const []}) {
  final int size = outputs.length;
  final List<Pointer<Utf8>> addressesPointers =
      outputs.map((output) => output.address.toNativeUtf8()).toList();
  final Pointer<Pointer<Utf8>> addressesPointerPointer = calloc(size);
  final List<Pointer<Utf8>> amountsPointers =
      outputs.map((output) => output.amount.toNativeUtf8()).toList();
  final Pointer<Pointer<Utf8>> amountsPointerPointer = calloc(size);

  for (int i = 0; i < size; i++) {
    addressesPointerPointer[i] = addressesPointers[i];
    amountsPointerPointer[i] = amountsPointers[i];
  }

  final int preferredInputsSize = preferredInputs.length;
  final List<Pointer<Utf8>> preferredInputsPointers =
      preferredInputs.map((output) => output.toNativeUtf8()).toList();
  final Pointer<Pointer<Utf8>> preferredInputsPointerPointer = calloc(preferredInputsSize);

  for (int i = 0; i < preferredInputsSize; i++) {
    preferredInputsPointerPointer[i] = preferredInputsPointers[i];
  }

  final paymentIdPointer = paymentId.toNativeUtf8();
  final errorMessagePointer = calloc<Utf8Box>();
  final pendingTransactionRawPointer = calloc<PendingTransactionRaw>();
  final created = transactionCreateMultDestNative(
          addressesPointerPointer,
          paymentIdPointer,
          amountsPointerPointer,
          size,
          priorityRaw,
          accountIndex,
          preferredInputsPointerPointer,
          preferredInputsSize,
          errorMessagePointer,
          pendingTransactionRawPointer) !=
      0;

  calloc.free(addressesPointerPointer);
  calloc.free(amountsPointerPointer);
  calloc.free(preferredInputsPointerPointer);

  addressesPointers.forEach((element) => calloc.free(element));
  amountsPointers.forEach((element) => calloc.free(element));
  preferredInputsPointers.forEach((element) => calloc.free(element));

  calloc.free(paymentIdPointer);

  if (!created) {
    final message = errorMessagePointer.ref.getValue();
    calloc.free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }

  return PendingTransactionDescription(
      amount: pendingTransactionRawPointer.ref.amount,
      fee: pendingTransactionRawPointer.ref.fee,
      hash: pendingTransactionRawPointer.ref.getHash(),
      hex: pendingTransactionRawPointer.ref.getHex(),
      txKey: pendingTransactionRawPointer.ref.getKey(),
      pointerAddress: pendingTransactionRawPointer.address);
}

void commitTransactionFromPointerAddress({required int address}) =>
    commitTransaction(transactionPointer: Pointer<PendingTransactionRaw>.fromAddress(address));

void commitTransaction({required Pointer<PendingTransactionRaw> transactionPointer}) {
  final errorMessagePointer = calloc<Utf8Box>();
  final isCommited = transactionCommitNative(transactionPointer, errorMessagePointer) != 0;

  if (!isCommited) {
    final message = errorMessagePointer.ref.getValue();
    calloc.free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }
}

PendingTransactionDescription _createTransactionSync(Map args) {
  final address = args['address'] as String;
  final paymentId = args['paymentId'] as String;
  final amount = args['amount'] as String?;
  final priorityRaw = args['priorityRaw'] as int;
  final accountIndex = args['accountIndex'] as int;
  final preferredInputs = args['preferredInputs'] as List<String>;

  return createTransactionSync(
      address: address,
      paymentId: paymentId,
      amount: amount,
      priorityRaw: priorityRaw,
      accountIndex: accountIndex,
      preferredInputs: preferredInputs);
}

PendingTransactionDescription _createTransactionMultDestSync(Map args) {
  final outputs = args['outputs'] as List<MoneroOutput>;
  final paymentId = args['paymentId'] as String;
  final priorityRaw = args['priorityRaw'] as int;
  final accountIndex = args['accountIndex'] as int;
  final preferredInputs = args['preferredInputs'] as List<String>;

  return createTransactionMultDestSync(
      outputs: outputs,
      paymentId: paymentId,
      priorityRaw: priorityRaw,
      accountIndex: accountIndex,
      preferredInputs: preferredInputs);
}

Future<PendingTransactionDescription> createTransaction(
        {required String address,
        required int priorityRaw,
        String? amount,
        String paymentId = '',
        int accountIndex = 0,
        List<String> preferredInputs = const []}) =>
    compute(_createTransactionSync, {
      'address': address,
      'paymentId': paymentId,
      'amount': amount,
      'priorityRaw': priorityRaw,
      'accountIndex': accountIndex,
      'preferredInputs': preferredInputs
    });

Future<PendingTransactionDescription> createTransactionMultDest(
        {required List<MoneroOutput> outputs,
        required int priorityRaw,
        String paymentId = '',
        int accountIndex = 0,
        List<String> preferredInputs = const []}) =>
    compute(_createTransactionMultDestSync, {
      'outputs': outputs,
      'paymentId': paymentId,
      'priorityRaw': priorityRaw,
      'accountIndex': accountIndex,
      'preferredInputs': preferredInputs
    });
