import 'dart:ffi';
import 'package:cw_monero/structs/ut8_box.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_monero/signatures.dart';
import 'package:cw_monero/types.dart';
import 'package:cw_monero/monero_api.dart';
import 'package:cw_monero/structs/transaction_info_row.dart';
import 'package:cw_monero/structs/pending_transaction.dart';
import 'package:cw_monero/exceptions/creation_transaction_exception.dart';

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

final transactionCommitNative = moneroApi
    .lookup<NativeFunction<transaction_commit>>('transaction_commit')
    .asFunction<TransactionCommit>();

refreshTransactions() => transactionsRefreshNative();

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
    String paymentId,
    String amount,
    int priorityRaw,
    int accountIndex = 0}) {
  final addressPointer = Utf8.toUtf8(address);
  final paymentIdPointer = Utf8.toUtf8(paymentId);
  final amountPointer = amount != null ? Utf8.toUtf8(amount) : nullptr;
  final errorMessagePointer = allocate<Utf8Box>();
  final pendingTransactionRawPointer = allocate<PendingTransactionRaw>();
  final created = transactionCreateNative(
          addressPointer,
          paymentIdPointer,
          amountPointer,
          priorityRaw,
          accountIndex,
          errorMessagePointer,
          pendingTransactionRawPointer) !=
      0;

  free(addressPointer);
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

commitTransactionFromPointerAddress({int address}) => commitTransaction(
    transactionPointer: Pointer<PendingTransactionRaw>.fromAddress(address));

commitTransaction({Pointer<PendingTransactionRaw> transactionPointer}) {
  final errorMessagePointer = allocate<Utf8Box>();
  final isCommited =
      transactionCommitNative(transactionPointer, errorMessagePointer) != 0;

  if (!isCommited) {
    final message = errorMessagePointer.ref.getValue();
    free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }
}

PendingTransactionDescription _createTransactionSync(Map args) =>
    createTransactionSync(
        address: args['address'],
        paymentId: args['paymentId'],
        amount: args['amount'],
        priorityRaw: args['priorityRaw'],
        accountIndex: args['accountIndex']);

Future<PendingTransactionDescription> createTransaction(
        {String address,
        String paymentId,
        String amount,
        int priorityRaw,
        int accountIndex = 0}) =>
    compute(_createTransactionSync, {
      'address': address,
      'paymentId': paymentId,
      'amount': amount,
      'priorityRaw': priorityRaw,
      'accountIndex': accountIndex
    });
