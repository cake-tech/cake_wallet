import 'dart:ffi';
import 'package:cw_haven/api/convert_utf8_to_string.dart';
import 'package:cw_haven/api/monero_output.dart';
import 'package:cw_haven/api/structs/ut8_box.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_haven/api/signatures.dart';
import 'package:cw_haven/api/types.dart';
import 'package:cw_haven/api/haven_api.dart';
import 'package:cw_haven/api/structs/transaction_info_row.dart';
import 'package:cw_haven/api/structs/pending_transaction.dart';
import 'package:cw_haven/api/exceptions/creation_transaction_exception.dart';

final transactionsRefreshNative = havenApi
    .lookup<NativeFunction<transactions_refresh>>('transactions_refresh')
    .asFunction<TransactionsRefresh>();

final transactionsCountNative = havenApi
    .lookup<NativeFunction<transactions_count>>('transactions_count')
    .asFunction<TransactionsCount>();

final transactionsGetAllNative = havenApi
    .lookup<NativeFunction<transactions_get_all>>('transactions_get_all')
    .asFunction<TransactionsGetAll>();

final transactionCreateNative = havenApi
    .lookup<NativeFunction<transaction_create>>('transaction_create')
    .asFunction<TransactionCreate>();

final transactionCreateMultDestNative = havenApi
    .lookup<NativeFunction<transaction_create_mult_dest>>('transaction_create_mult_dest')
    .asFunction<TransactionCreateMultDest>();

final transactionCommitNative = havenApi
    .lookup<NativeFunction<transaction_commit>>('transaction_commit')
    .asFunction<TransactionCommit>();

final getTxKeyNative = havenApi
    .lookup<NativeFunction<get_tx_key>>('get_tx_key')
    .asFunction<GetTxKey>();

String getTxKey(String txId) {
  final txIdPointer = Utf8.toUtf8(txId);
  final keyPointer = getTxKeyNative(txIdPointer);

  free(txIdPointer);

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
    {String address,
    String assetType,
    String paymentId,
    String amount,
    int priorityRaw,
    int accountIndex = 0}) {
  final addressPointer = Utf8.toUtf8(address);
  final assetTypePointer = Utf8.toUtf8(assetType);
  final paymentIdPointer = Utf8.toUtf8(paymentId);
  final amountPointer = amount != null ? Utf8.toUtf8(amount) : nullptr;
  final errorMessagePointer = allocate<Utf8Box>();
  final pendingTransactionRawPointer = allocate<PendingTransactionRaw>();
  final created = transactionCreateNative(
          addressPointer,
          assetTypePointer,
          paymentIdPointer,
          amountPointer,
          priorityRaw,
          accountIndex,
          errorMessagePointer,
          pendingTransactionRawPointer) !=
      0;

  free(addressPointer);
  free(assetTypePointer);
  free(paymentIdPointer);

  if (amountPointer != nullptr) {
    free(amountPointer);
  }

  if (!created) {
    final message = errorMessagePointer.ref.getValue();
    free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }

  return PendingTransactionDescription(
      amount: pendingTransactionRawPointer.ref.amount,
      fee: pendingTransactionRawPointer.ref.fee,
      hash: pendingTransactionRawPointer.ref.getHash(),
      pointerAddress: pendingTransactionRawPointer.address);
}

PendingTransactionDescription createTransactionMultDestSync(
    {List<MoneroOutput> outputs,
      String assetType,
      String paymentId,
      int priorityRaw,
      int accountIndex = 0}) {
  final int size = outputs.length;
  final List<Pointer<Utf8>> addressesPointers = outputs.map((output) =>
      Utf8.toUtf8(output.address)).toList();
  final Pointer<Pointer<Utf8>> addressesPointerPointer = allocate(count: size);
  final List<Pointer<Utf8>> amountsPointers = outputs.map((output) =>
      Utf8.toUtf8(output.amount)).toList();
  final Pointer<Pointer<Utf8>> amountsPointerPointer = allocate(count: size);

  for (int i = 0; i < size; i++) {
    addressesPointerPointer[i] = addressesPointers[i];
    amountsPointerPointer[i] = amountsPointers[i];
  }

  final assetTypePointer = Utf8.toUtf8(assetType);
  final paymentIdPointer = Utf8.toUtf8(paymentId);
  final errorMessagePointer = allocate<Utf8Box>();
  final pendingTransactionRawPointer = allocate<PendingTransactionRaw>();
  final created = transactionCreateMultDestNative(
      addressesPointerPointer,
      assetTypePointer,
      paymentIdPointer,
      amountsPointerPointer,
      size,
      priorityRaw,
      accountIndex,
      errorMessagePointer,
      pendingTransactionRawPointer) !=
      0;

  free(addressesPointerPointer);
  free(assetTypePointer);
  free(amountsPointerPointer);

  addressesPointers.forEach((element) => free(element));
  amountsPointers.forEach((element) => free(element));

  free(paymentIdPointer);

  if (!created) {
    final message = errorMessagePointer.ref.getValue();
    free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }

  return PendingTransactionDescription(
      amount: pendingTransactionRawPointer.ref.amount,
      fee: pendingTransactionRawPointer.ref.fee,
      hash: pendingTransactionRawPointer.ref.getHash(),
      pointerAddress: pendingTransactionRawPointer.address);
}

void commitTransactionFromPointerAddress({int address}) => commitTransaction(
    transactionPointer: Pointer<PendingTransactionRaw>.fromAddress(address));

void commitTransaction({Pointer<PendingTransactionRaw> transactionPointer}) {
  final errorMessagePointer = allocate<Utf8Box>();
  final isCommited =
      transactionCommitNative(transactionPointer, errorMessagePointer) != 0;

  if (!isCommited) {
    final message = errorMessagePointer.ref.getValue();
    free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }
}

PendingTransactionDescription _createTransactionSync(Map args) {
  final address = args['address'] as String;
  final assetType = args['assetType'] as String;
  final paymentId = args['paymentId'] as String;
  final amount = args['amount'] as String;
  final priorityRaw = args['priorityRaw'] as int;
  final accountIndex = args['accountIndex'] as int;

  return createTransactionSync(
      address: address,
      assetType: assetType,
      paymentId: paymentId,
      amount: amount,
      priorityRaw: priorityRaw,
      accountIndex: accountIndex);
}

PendingTransactionDescription _createTransactionMultDestSync(Map args) {
  final outputs = args['outputs'] as List<MoneroOutput>;
  final assetType = args['assetType'] as String;
  final paymentId = args['paymentId'] as String;
  final priorityRaw = args['priorityRaw'] as int;
  final accountIndex = args['accountIndex'] as int;

  return createTransactionMultDestSync(
      outputs: outputs,
      assetType: assetType,
      paymentId: paymentId,
      priorityRaw: priorityRaw,
      accountIndex: accountIndex);
}

Future<PendingTransactionDescription> createTransaction(
        {String address,
         String assetType,
        String paymentId = '',
        String amount,
        int priorityRaw,
        int accountIndex = 0}) =>
    compute(_createTransactionSync, {
      'address': address,
      'assetType': assetType,
      'paymentId': paymentId,
      'amount': amount,
      'priorityRaw': priorityRaw,
      'accountIndex': accountIndex
    });

Future<PendingTransactionDescription> createTransactionMultDest(
    {List<MoneroOutput> outputs,
      String assetType,
      String paymentId = '',
      int priorityRaw,
      int accountIndex = 0}) =>
    compute(_createTransactionMultDestSync, {
      'outputs': outputs,
      'assetType': assetType,
      'paymentId': paymentId,
      'priorityRaw': priorityRaw,
      'accountIndex': accountIndex
    });
