import 'dart:ffi';
import 'package:cw_zano/api/convert_utf8_to_string.dart';
import 'package:cw_zano/api/zano_output.dart';
import 'package:cw_zano/api/structs/ut8_box.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_zano/api/signatures.dart';
import 'package:cw_zano/api/types.dart';
import 'package:cw_zano/api/zano_api.dart';
import 'package:cw_zano/api/structs/transaction_info_row.dart';
import 'package:cw_zano/api/structs/pending_transaction.dart';
import 'package:cw_zano/api/exceptions/creation_transaction_exception.dart';

/**final transactionsRefreshNative = zanoApi
    .lookup<NativeFunction<transactions_refresh>>('transactions_refresh')
    .asFunction<TransactionsRefresh>();*/

/**final transactionsCountNative = zanoApi
    .lookup<NativeFunction<transactions_count>>('transactions_count')
    .asFunction<TransactionsCount>();*/

final transactionsGetAllNative = zanoApi
    .lookup<NativeFunction<transactions_get_all>>('transactions_get_all')
    .asFunction<TransactionsGetAll>();

final transactionCreateNative = zanoApi
    .lookup<NativeFunction<transaction_create>>('transaction_create')
    .asFunction<TransactionCreate>();

final transactionCreateMultDestNative = zanoApi
    .lookup<NativeFunction<transaction_create_mult_dest>>(
        'transaction_create_mult_dest')
    .asFunction<TransactionCreateMultDest>();

final transactionCommitNative = zanoApi
    .lookup<NativeFunction<transaction_commit>>('transaction_commit')
    .asFunction<TransactionCommit>();

final getTxKeyNative = zanoApi
    .lookup<NativeFunction<get_tx_key>>('get_tx_key')
    .asFunction<GetTxKey>();

String getTxKey(String txId) {
  final txIdPointer = txId.toNativeUtf8();
  final keyPointer = getTxKeyNative(txIdPointer);

  calloc.free(txIdPointer);

  if (keyPointer != null) {
    return convertUTF8ToString(pointer: keyPointer);
  }

  return '';
}

void refreshTransactions() {
  // TODO: fix it
  //transactionsRefreshNative();
  debugPrint("refreshing transactions");
}

int countOfTransactions() {
  //return transactionsCountNative();
  // TODO: fix it
  debugPrint("count of transactions");
  return 0;
}

List<TransactionInfoRow> getAllTransations() {
  // TODO: fix it
  return [];
  /*final size = transactionsCountNative();
  final transactionsPointer = transactionsGetAllNative();
  final transactionsAddresses = transactionsPointer.asTypedList(size);

  return transactionsAddresses
      .map((addr) => Pointer<TransactionInfoRow>.fromAddress(addr).ref)
      .toList();*/
}

PendingTransactionDescription createTransactionSync(
    {required String address,
    required String assetType,
    required String paymentId,
    required int priorityRaw,
    String? amount}) {
  final addressPointer = address.toNativeUtf8();
  final assetTypePointer = assetType.toNativeUtf8();
  final paymentIdPointer = paymentId.toNativeUtf8();
  final amountPointer = amount != null ? amount.toNativeUtf8() : nullptr;
  final errorMessagePointer = calloc<Utf8Box>();
  final pendingTransactionRawPointer = calloc<PendingTransactionRaw>();
  final created = transactionCreateNative(
          addressPointer,
          assetTypePointer,
          paymentIdPointer,
          amountPointer,
          priorityRaw,
          errorMessagePointer,
          pendingTransactionRawPointer) !=
      0;

  calloc.free(addressPointer);
  calloc.free(assetTypePointer);
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
      pointerAddress: pendingTransactionRawPointer.address);
}

PendingTransactionDescription createTransactionMultDestSync(
    {required List<ZanoOutput> outputs,
    required String assetType,
    required String paymentId,
    required int priorityRaw}) {
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

  final assetTypePointer = assetType.toNativeUtf8();
  final paymentIdPointer = paymentId.toNativeUtf8();
  final errorMessagePointer = calloc<Utf8Box>();
  final pendingTransactionRawPointer = calloc<PendingTransactionRaw>();
  final created = transactionCreateMultDestNative(
          addressesPointerPointer,
          assetTypePointer,
          paymentIdPointer,
          amountsPointerPointer,
          size,
          priorityRaw,
          errorMessagePointer,
          pendingTransactionRawPointer) !=
      0;

  calloc.free(addressesPointerPointer);
  calloc.free(assetTypePointer);
  calloc.free(amountsPointerPointer);

  addressesPointers.forEach((element) => calloc.free(element));
  amountsPointers.forEach((element) => calloc.free(element));

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
      pointerAddress: pendingTransactionRawPointer.address);
}

void commitTransactionFromPointerAddress({required int address}) =>
    commitTransaction(
        transactionPointer:
            Pointer<PendingTransactionRaw>.fromAddress(address));

void commitTransaction(
    {required Pointer<PendingTransactionRaw> transactionPointer}) {
  final errorMessagePointer = calloc<Utf8Box>();
  final isCommited =
      transactionCommitNative(transactionPointer, errorMessagePointer) != 0;

  if (!isCommited) {
    final message = errorMessagePointer.ref.getValue();
    calloc.free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }
}

PendingTransactionDescription _createTransactionSync(Map args) {
  final address = args['address'] as String;
  final assetType = args['assetType'] as String;
  final paymentId = args['paymentId'] as String;
  final amount = args['amount'] as String;
  final priorityRaw = args['priorityRaw'] as int;

  return createTransactionSync(
      address: address,
      assetType: assetType,
      paymentId: paymentId,
      amount: amount,
      priorityRaw: priorityRaw);
}

PendingTransactionDescription _createTransactionMultDestSync(Map args) {
  final outputs = args['outputs'] as List<ZanoOutput>;
  final assetType = args['assetType'] as String;
  final paymentId = args['paymentId'] as String;
  final priorityRaw = args['priorityRaw'] as int;

  return createTransactionMultDestSync(
      outputs: outputs,
      assetType: assetType,
      paymentId: paymentId,
      priorityRaw: priorityRaw);
}

Future<PendingTransactionDescription> createTransaction(
        {required String address,
        required String assetType,
        required int priorityRaw,
        String? amount,
        String paymentId = ''}) =>
    compute(_createTransactionSync, {
      'address': address,
      'assetType': assetType,
      'paymentId': paymentId,
      'amount': amount,
      'priorityRaw': priorityRaw,
    });

Future<PendingTransactionDescription> createTransactionMultDest(
        {required List<ZanoOutput> outputs,
        required int priorityRaw,
        String? assetType,
        String paymentId = ''}) =>
    compute(_createTransactionMultDestSync, {
      'outputs': outputs,
      'assetType': assetType,
      'paymentId': paymentId,
      'priorityRaw': priorityRaw,
    });
