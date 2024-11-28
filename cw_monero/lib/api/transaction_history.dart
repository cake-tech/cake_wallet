import 'dart:ffi';
import 'dart:isolate';

import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_monero/api/monero_output.dart';
import 'package:cw_monero/api/structs/pending_transaction.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:cw_monero/exceptions/monero_transaction_creation_exception.dart';
import 'package:ffi/ffi.dart';
import 'package:monero/monero.dart' as monero;
import 'package:monero/src/generated_bindings_monero.g.dart' as monero_gen;
import 'package:mutex/mutex.dart';


String getTxKey(String txId) {
  final txKey = monero.Wallet_getTxKey(wptr!, txid: txId);
  final status = monero.Wallet_status(wptr!);
  if (status != 0) {
    final error = monero.Wallet_errorString(wptr!);
    return "";
  }
  return txKey;
}
final txHistoryMutex = Mutex();
monero.TransactionHistory? txhistory;
bool isRefreshingTx = false;
Future<void> refreshTransactions() async {
  if (isRefreshingTx == true) return;
  isRefreshingTx = true;
  txhistory ??= monero.Wallet_history(wptr!);
  final ptr = txhistory!.address;
  await txHistoryMutex.acquire();
  await Isolate.run(() {
    monero.TransactionHistory_refresh(Pointer.fromAddress(ptr));
  });
  txHistoryMutex.release();
  isRefreshingTx = false;
}

int countOfTransactions() => monero.TransactionHistory_count(txhistory!);

Future<List<Transaction>> getAllTransactions() async {
  List<Transaction> dummyTxs = [];
  
  await txHistoryMutex.acquire();
  txhistory ??= monero.Wallet_history(wptr!);
  int size = countOfTransactions();
  final list = List.generate(size, (index) => Transaction(txInfo: monero.TransactionHistory_transaction(txhistory!, index: index)));
  txHistoryMutex.release();
  final accts = monero.Wallet_numSubaddressAccounts(wptr!);
  for (var i = 0; i < accts; i++) {  
    final fullBalance = monero.Wallet_balance(wptr!, accountIndex: i);
    final availBalance = monero.Wallet_unlockedBalance(wptr!, accountIndex: i);
    if (fullBalance > availBalance) {
      if (list.where((element) => element.accountIndex == i && element.isConfirmed == false).isEmpty) {
        dummyTxs.add(
          Transaction.dummy(
            displayLabel: "",
            description: "",
            fee: 0,
            confirmations: 0,
            blockheight: 0,
            accountIndex: i,
            addressIndex: 0,
            addressIndexList: [0],
            paymentId: "",
            amount: fullBalance - availBalance,
            isSpend: false,
            hash: "pending",
            key: "",
            txInfo: Pointer.fromAddress(0),
          )..timeStamp = DateTime.now()
        );
      }
    }
  }
  list.addAll(dummyTxs);
  return list;
}

Transaction getTransaction(String txId) {
  return Transaction(txInfo: monero.TransactionHistory_transactionById(txhistory!, txid: txId));
}

Future<PendingTransactionDescription> createTransactionSync(
    {required String address,
    required String paymentId,
    required int priorityRaw,
    String? amount,
    int accountIndex = 0,
    List<String> preferredInputs = const []}) async {

  final amt = amount == null ? 0 : monero.Wallet_amountFromString(amount);

  final waddr = wptr!.address;

  // force reconnection in case the os killed the connection?
  // fixes failed to get block height error.
  Isolate.run(() async {
    monero.Wallet_synchronized(Pointer.fromAddress(waddr));
  });

  final address_ = address.toNativeUtf8(); 
  final paymentId_ = paymentId.toNativeUtf8();
  if (preferredInputs.isEmpty) {
    throw MoneroTransactionCreationException("No inputs provided, transaction cannot be constructed");
  }

  final preferredInputs_ = preferredInputs.join(monero.defaultSeparatorStr).toNativeUtf8();

  final addraddr = address_.address;
  final paymentIdAddr = paymentId_.address;
  final preferredInputsAddr = preferredInputs_.address;
  final spaddr = monero.defaultSeparator.address;
  final pendingTx = Pointer<Void>.fromAddress(await Isolate.run(() {
    final tx = monero_gen.MoneroC(DynamicLibrary.open(monero.libPath)).MONERO_Wallet_createTransaction(
      Pointer.fromAddress(waddr),
      Pointer.fromAddress(addraddr).cast(),
      Pointer.fromAddress(paymentIdAddr).cast(),
      amt,
      1,
      priorityRaw,
      accountIndex,
      Pointer.fromAddress(preferredInputsAddr).cast(),
      Pointer.fromAddress(spaddr),
    );
    return tx.address;
  }));
  calloc.free(address_);
  calloc.free(paymentId_);
  calloc.free(preferredInputs_);
  final String? error = (() {
    final status = monero.PendingTransaction_status(pendingTx);
    if (status == 0) {
      return null;
    }
    return monero.PendingTransaction_errorString(pendingTx);
  })();

  if (error != null) {
    String message = error;
    if (message.contains("RPC error")) {
      message = "Invalid node response, please try again or switch node\n\ntrace: $message";
    }
    throw CreationTransactionException(message: message);
  }

  final rAmt = monero.PendingTransaction_amount(pendingTx);
  final rFee = monero.PendingTransaction_fee(pendingTx);
  final rHash = monero.PendingTransaction_txid(pendingTx, '');
  final rTxKey = rHash;

  return PendingTransactionDescription(
      amount: rAmt,
      fee: rFee,
      hash: rHash,
      hex: '',
      txKey: rTxKey,
      pointerAddress: pendingTx.address,
    );
}

PendingTransactionDescription createTransactionMultDestSync(
    {required List<MoneroOutput> outputs,
    required String paymentId,
    required int priorityRaw,
    int accountIndex = 0,
    List<String> preferredInputs = const []}) {
  
  final dstAddrs = outputs.map((e) => e.address).toList();
  final amounts = outputs.map((e) => monero.Wallet_amountFromString(e.amount)).toList();

  // print("multDest: dstAddrs: $dstAddrs");
  // print("multDest: amounts: $amounts");

  final txptr = monero.Wallet_createTransactionMultDest(
    wptr!,
    dstAddr: dstAddrs,
    isSweepAll: false,
    amounts: amounts,
    mixinCount: 0,
    pendingTransactionPriority: priorityRaw,
    subaddr_account: accountIndex,
  );
  if (monero.PendingTransaction_status(txptr) != 0) {
    throw CreationTransactionException(message: monero.PendingTransaction_errorString(txptr));
  }
  return PendingTransactionDescription(
    amount: monero.PendingTransaction_amount(txptr),
    fee: monero.PendingTransaction_fee(txptr),
    hash: monero.PendingTransaction_txid(txptr, ''),
    hex: monero.PendingTransaction_txid(txptr, ''),
    txKey: monero.PendingTransaction_txid(txptr, ''),
    pointerAddress: txptr.address,
  );
}

String? commitTransactionFromPointerAddress({required int address, required bool useUR}) =>
    commitTransaction(transactionPointer: monero.PendingTransaction.fromAddress(address), useUR: useUR);

String? commitTransaction({required monero.PendingTransaction transactionPointer, required bool useUR}) {
  final txCommit = useUR
    ? monero.PendingTransaction_commitUR(transactionPointer, 120)
    : monero.PendingTransaction_commit(transactionPointer, filename: '', overwrite: false);

  String? error = (() {
    final status = monero.PendingTransaction_status(transactionPointer.cast());
    if (status == 0) {
      return null;
    }
    return monero.PendingTransaction_errorString(transactionPointer.cast());
  })();
  if (error == null) {
    error = (() {
      final status = monero.Wallet_status(wptr!);
      if (status == 0) {
        return null;
      }
      return monero.Wallet_errorString(wptr!);
    })();
  
  }
  if (error != null) {
    throw CreationTransactionException(message: error);
  }
  if (useUR) {
    return txCommit as String?;
  } else {
    return null;
  }
}

Future<PendingTransactionDescription> _createTransactionSync(Map args) async {
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
        List<String> preferredInputs = const []}) async =>
    _createTransactionSync({
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
        List<String> preferredInputs = const []}) async =>
    _createTransactionMultDestSync({
      'outputs': outputs,
      'paymentId': paymentId,
      'priorityRaw': priorityRaw,
      'accountIndex': accountIndex,
      'preferredInputs': preferredInputs
    });


class Transaction {
  final String displayLabel;
  late final String subaddressLabel = monero.Wallet_getSubaddressLabel(
    wptr!,
    accountIndex: accountIndex,
    addressIndex: addressIndex,
  );
  late final String address = getAddress(
    accountIndex: accountIndex,
    addressIndex: addressIndex,
  );
  late final List<String> addressList = List.generate(addressIndexList.length, (index) =>
    getAddress(
    accountIndex: accountIndex,
    addressIndex: addressIndexList[index],
    ));
  final String description;
  final int fee;
  final int confirmations;
  late final bool isPending = confirmations < 10;
  final int blockheight;
  final int addressIndex;
  final int accountIndex;
  final List<int> addressIndexList;
  final String paymentId;
  final int amount;
  final bool isSpend;
  late DateTime timeStamp;
  late final bool isConfirmed = !isPending;
  final String hash;
  final String key;

  Map<String, dynamic> toJson() {
    return {
      "displayLabel": displayLabel,
      "subaddressLabel": subaddressLabel,
      "address": address,
      "description": description,
      "fee": fee,
      "confirmations": confirmations,
      "isPending": isPending,
      "blockheight": blockheight,
      "accountIndex": accountIndex,
      "addressIndex": addressIndex,
      "paymentId": paymentId,
      "amount": amount,
      "isSpend": isSpend,
      "timeStamp": timeStamp.toIso8601String(),
      "isConfirmed": isConfirmed,
      "hash": hash,
    };
  }

  // final SubAddress? subAddress;
  // List<Transfer> transfers = [];
  // final int txIndex;
  final monero.TransactionInfo txInfo;
  Transaction({
    required this.txInfo,
  })  : displayLabel = monero.TransactionInfo_label(txInfo),
        hash = monero.TransactionInfo_hash(txInfo),
        timeStamp = DateTime.fromMillisecondsSinceEpoch(
          monero.TransactionInfo_timestamp(txInfo) * 1000,
        ),
        isSpend = monero.TransactionInfo_direction(txInfo) ==
            monero.TransactionInfo_Direction.Out,
        amount = monero.TransactionInfo_amount(txInfo),
        paymentId = monero.TransactionInfo_paymentId(txInfo),
        accountIndex = monero.TransactionInfo_subaddrAccount(txInfo),
        addressIndex = int.tryParse(monero.TransactionInfo_subaddrIndex(txInfo).split(", ")[0]) ?? 0,
        addressIndexList = monero.TransactionInfo_subaddrIndex(txInfo).split(", ").map((e) => int.tryParse(e) ?? 0).toList(),
        blockheight = monero.TransactionInfo_blockHeight(txInfo),
        confirmations = monero.TransactionInfo_confirmations(txInfo),
        fee = monero.TransactionInfo_fee(txInfo),
        description = monero.TransactionInfo_description(txInfo),
        key = getTxKey(monero.TransactionInfo_hash(txInfo));

  Transaction.dummy({
    required this.displayLabel,
    required this.description,
    required this.fee,
    required this.confirmations,
    required this.blockheight,
    required this.accountIndex,
    required this.addressIndexList,
    required this.addressIndex,
    required this.paymentId,
    required this.amount,
    required this.isSpend,
    required this.hash,
    required this.key,
    required this.txInfo
  });
}
