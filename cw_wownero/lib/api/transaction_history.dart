import 'dart:ffi';

import 'package:cw_wownero/api/convert_utf8_to_string.dart';
import 'package:cw_wownero/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_wownero/api/signatures.dart';
import 'package:cw_wownero/api/structs/pending_transaction.dart';
import 'package:cw_wownero/api/structs/transaction_info_row.dart';
import 'package:cw_wownero/api/structs/ut8_box.dart';
import 'package:cw_wownero/api/types.dart';
import 'package:cw_wownero/api/wownero_api.dart';
import 'package:cw_wownero/api/wownero_output.dart';
import 'package:ffi/ffi.dart';
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:flutter/foundation.dart';

final transactionsRefreshNative = wowneroApi
    .lookup<NativeFunction<transactions_refresh>>('transactions_refresh')
    .asFunction<TransactionsRefresh>();

final transactionsCountNative = wowneroApi
    .lookup<NativeFunction<transactions_count>>('transactions_count')
    .asFunction<TransactionsCount>();

final transactionsGetAllNative = wowneroApi
    .lookup<NativeFunction<transactions_get_all>>('transactions_get_all')
    .asFunction<TransactionsGetAll>();

final transactionCreateNative = wowneroApi
    .lookup<NativeFunction<transaction_create>>('transaction_create')
    .asFunction<TransactionCreate>();

final transactionCreateMultDestNative = wowneroApi
    .lookup<NativeFunction<transaction_create_mult_dest>>(
        'transaction_create_mult_dest')
    .asFunction<TransactionCreateMultDest>();

final transactionCommitNative = wowneroApi
    .lookup<NativeFunction<transaction_commit>>('transaction_commit')
    .asFunction<TransactionCommit>();

final getTxKeyNative = wowneroApi
    .lookup<NativeFunction<get_tx_key>>('get_tx_key')
    .asFunction<GetTxKey>();

String? getTxKey(String txId) {
  final txIdPointer = txId.toNativeUtf8();
  final keyPointer = getTxKeyNative(txIdPointer);

  pkgffi.calloc.free(txIdPointer);

  if (keyPointer != null) {
    return convertUTF8ToString(pointer: keyPointer);
  }

  return null;
}

void refreshTransactions() => transactionsRefreshNative();

int countOfTransactions() => transactionsCountNative();

List<TransactionInfoRow> getAllTransations() {
  final size = transactionsCountNative();
  final transactionsPointer = transactionsGetAllNative();
  final transactionsAddresses = transactionsPointer.asTypedList(size);

  return transactionsAddresses
      .map((addr) => Pointer<TransactionInfoRow>.fromAddress(addr).ref)
      .toList();
}

PendingTransactionDescription createTransactionSync(
    {required String address,
    required String paymentId,
    String? amount,
    int? priorityRaw,
    int? accountIndex = 0}) {
  final addressPointer = address.toNativeUtf8();
  final paymentIdPointer = paymentId.toNativeUtf8();
  final amountPointer = amount != null ? amount.toNativeUtf8() : nullptr;

  final errorMessagePointer =
      pkgffi.calloc.allocate<Utf8Box>(sizeOf<Utf8Box>());
  final pendingTransactionRawPointer = pkgffi.calloc
      .allocate<PendingTransactionRaw>(sizeOf<PendingTransactionRaw>());
  final created = transactionCreateNative(
          addressPointer,
          paymentIdPointer,
          amountPointer,
          priorityRaw,
          accountIndex,
          errorMessagePointer,
          pendingTransactionRawPointer) !=
      0;

  pkgffi.calloc.free(addressPointer);
  pkgffi.calloc.free(paymentIdPointer);

  if (amountPointer != nullptr) {
    pkgffi.calloc.free(amountPointer);
  }

  if (!created) {
    final message = errorMessagePointer.ref.getValue();
    pkgffi.calloc.free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }

  return PendingTransactionDescription(
      amount: pendingTransactionRawPointer.ref.amount,
      fee: pendingTransactionRawPointer.ref.fee,
      hash: pendingTransactionRawPointer.ref.getHash(),
      pointerAddress: pendingTransactionRawPointer.address);
}

PendingTransactionDescription createTransactionMultDestSync(
    {required List<WowneroOutput> outputs,
    required String paymentId,
    int? priorityRaw,
    int? accountIndex = 0}) {
  final int size = outputs.length;
  final List<Pointer<Utf8>> addressesPointers =
      outputs.map((output) => output.address!.toNativeUtf8()).toList();
  final Pointer<Pointer<Utf8>> addressesPointerPointer =
      pkgffi.calloc.allocate(size * sizeOf<Pointer<Utf8>>());
  final List<Pointer<Utf8>> amountsPointers =
      outputs.map((output) => output.amount.toNativeUtf8()).toList();
  final Pointer<Pointer<Utf8>> amountsPointerPointer =
      pkgffi.calloc.allocate(size * sizeOf<Pointer<Utf8>>());

  for (int i = 0; i < size; i++) {
    addressesPointerPointer[i] = addressesPointers[i];
    amountsPointerPointer[i] = amountsPointers[i];
  }

  final paymentIdPointer = paymentId.toNativeUtf8();
  final errorMessagePointer =
      pkgffi.calloc.allocate<Utf8Box>(sizeOf<Utf8Box>());
  final pendingTransactionRawPointer = pkgffi.calloc
      .allocate<PendingTransactionRaw>(sizeOf<PendingTransactionRaw>());
  final created = transactionCreateMultDestNative(
          addressesPointerPointer,
          paymentIdPointer,
          amountsPointerPointer,
          size,
          priorityRaw,
          accountIndex,
          errorMessagePointer,
          pendingTransactionRawPointer) !=
      0;
  pkgffi.calloc.free(addressesPointerPointer);
  pkgffi.calloc.free(amountsPointerPointer);

  addressesPointers.forEach((element) => pkgffi.calloc.free(element));
  amountsPointers.forEach((element) => pkgffi.calloc.free(element));

  pkgffi.calloc.free(paymentIdPointer);

  if (!created) {
    final message = errorMessagePointer.ref.getValue();
    pkgffi.calloc.free(errorMessagePointer);
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

void commitTransaction({Pointer<PendingTransactionRaw>? transactionPointer}) {
  final errorMessagePointer =
      pkgffi.calloc.allocate<Utf8Box>(sizeOf<Utf8Box>());
  final isCommited =
      transactionCommitNative(transactionPointer!, errorMessagePointer) != 0;

  if (!isCommited) {
    final message = errorMessagePointer.ref.getValue();
    pkgffi.calloc.free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }
}

PendingTransactionDescription _createTransactionSync(Map args) {
  final address = args['address'] as String;
  final paymentId = args['paymentId'] as String;
  final amount = args['amount'] as String?;
  final priorityRaw = args['priorityRaw'] as int?;
  final accountIndex = args['accountIndex'] as int?;

  return createTransactionSync(
      address: address,
      paymentId: paymentId,
      amount: amount,
      priorityRaw: priorityRaw,
      accountIndex: accountIndex);
}

PendingTransactionDescription _createTransactionMultDestSync(Map args) {
  final outputs = args['outputs'] as List<WowneroOutput>;
  final paymentId = args['paymentId'] as String;
  final priorityRaw = args['priorityRaw'] as int?;
  final accountIndex = args['accountIndex'] as int?;

  return createTransactionMultDestSync(
      outputs: outputs,
      paymentId: paymentId,
      priorityRaw: priorityRaw,
      accountIndex: accountIndex);
}

Future<PendingTransactionDescription> createTransaction(
        {String? address,
        String paymentId = '',
        String? amount,
        int? priorityRaw,
        int? accountIndex = 0}) =>
    compute(_createTransactionSync, {
      'address': address,
      'paymentId': paymentId,
      'amount': amount,
      'priorityRaw': priorityRaw,
      'accountIndex': accountIndex
    });

Future<PendingTransactionDescription> createTransactionMultDest(
        {List<WowneroOutput>? outputs,
        String paymentId = '',
        int? priorityRaw,
        int? accountIndex = 0}) =>
    compute(_createTransactionMultDestSync, {
      'outputs': outputs,
      'paymentId': paymentId,
      'priorityRaw': priorityRaw,
      'accountIndex': accountIndex
    });
