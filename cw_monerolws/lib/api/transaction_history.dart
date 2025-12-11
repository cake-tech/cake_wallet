import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monerolws/api/account_list.dart';
import 'package:cw_monerolws/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_monerolws/api/monero_output.dart';
import 'package:cw_monerolws/api/structs/pending_transaction.dart';
import 'package:cw_monerolws/api/wallet.dart';
import 'package:cw_monerolws/exceptions/monero_transaction_creation_exception.dart';
import 'package:ffi/ffi.dart';
import 'package:monero/src/monero.dart'; // // imported from git
import 'package:monerolws/monerolws.dart' as monero_lws; // add to pubspec
import 'package:monero/src/wallet2.dart'; // imported from git
import 'package:monero/src/generated_bindings_monero.g.dart' as monero_gen;
import 'package:mutex/mutex.dart';

Map<int, Map<String, String>> txKeys = {};
String getTxKey(String txId) {
  txKeys[currentWallet!.ffiAddress()] ??= {};
  if (txKeys[currentWallet!.ffiAddress()]![txId] != null) {
    return txKeys[currentWallet!.ffiAddress()]![txId]!;
  }
  final txKey = currentWallet!.getTxKey(txid: txId);
  final status = currentWallet!.status();
  if (status != 0) {
    currentWallet!.errorString();
    txKeys[currentWallet!.ffiAddress()]![txId] = "";
    return "";
  }
  txKeys[currentWallet!.ffiAddress()]![txId] = txKey;
  return txKey;
}

final txHistoryMutex = Mutex();
Wallet2TransactionHistory? txhistory;
bool isRefreshingTx = false;
Future<void> refreshTransactions() async {
  if (isRefreshingTx == true) return;
  isRefreshingTx = true;
  txhistory ??= currentWallet!.history();
  final ptr = txhistory!.ffiAddress();
  await txHistoryMutex.acquire();
  await Isolate.run(() {
    monero.TransactionHistory_refresh(Pointer.fromAddress(ptr));
  });
  await Future.delayed(Duration.zero);
  txHistoryMutex.release();
  isRefreshingTx = false;
}

int countOfTransactions() => txhistory!.count();

Future<List<Transaction>> getAllTransactions() async {
  List<Transaction> dummyTxs = [];

  await txHistoryMutex.acquire();
  txhistory ??= currentWallet!.history();
  final startAddress = txhistory!.ffiAddress() * currentWallet!.ffiAddress();
  int size = countOfTransactions();
  final list = <Transaction>[];
  for (int index = 0; index < size; index++) {
    if (index % 25 == 0) {
      // Give main thread a chance to do other things.
      await Future.delayed(Duration.zero);
    }
    if (txhistory!.ffiAddress() * currentWallet!.ffiAddress() != startAddress) {
      printV("Loop broken because txhistory!.address * wptr!.address != startAddress");
      break;
    }
    final txInfo = txhistory!.transaction(index);
    final txHash = txInfo.hash();
    txCache[currentWallet!.ffiAddress()] ??= {};
    txCache[currentWallet!.ffiAddress()]![txHash] = Transaction(txInfo: txInfo);
    list.add(txCache[currentWallet!.ffiAddress()]![txHash]!);
  }
  txHistoryMutex.release();
  final accts = currentWallet!.numSubaddressAccounts();
  for (var i = 0; i < accts; i++) {
    final fullBalance = currentWallet!.balance(accountIndex: i);
    final availBalance = currentWallet!.unlockedBalance(accountIndex: i);
    if (fullBalance > availBalance) {
      if (list.where((element) => element.accountIndex == i && element.isConfirmed == false).isEmpty) {
        dummyTxs.add(Transaction.dummy(
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
          txInfo: DummyTransaction(),
        )..timeStamp = DateTime.now());
      }
    }
  }
  list.addAll(dummyTxs);
  return list;
}

class DummyTransaction implements Wallet2TransactionInfo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<int, Map<String, Transaction>> txCache = {};
Future<Transaction> getTransaction(String txId) async {
  if (txCache[currentWallet!.ffiAddress()] != null && txCache[currentWallet!.ffiAddress()]![txId] != null) {
    return txCache[currentWallet!.ffiAddress()]![txId]!;
  }
  await txHistoryMutex.acquire();
  final tx = txhistory!.transactionById(txId);
  final txDart = Transaction(txInfo: tx);
  txCache[currentWallet!.ffiAddress()] ??= {};
  txCache[currentWallet!.ffiAddress()]![txId] = txDart;
  txHistoryMutex.release();
  return txDart;
}

Future<PendingTransactionDescription> createTransactionSync({required String address, required String paymentId, required int priorityRaw, String? amount, int accountIndex = 0, List<String> preferredInputs = const []}) async {
  final amt = amount == null ? 0 : currentWallet!.amountFromString(amount);

  final waddr = currentWallet!.ffiAddress();

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
  final pendingTxPtr = Pointer<Void>.fromAddress(await Isolate.run(() {
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
  final Wallet2PendingTransaction pendingTx = MoneroPendingTransaction(pendingTxPtr);
  calloc.free(address_);
  calloc.free(paymentId_);
  calloc.free(preferredInputs_);
  final String? error = (() {
    final status = pendingTx.status();
    if (status == 0) {
      return null;
    }
    return pendingTx.errorString();
  })();

  if (error != null) {
    String message = error;
    if (message.contains("RPC error")) {
      message = "Invalid node response, please try again or switch node\n\ntrace: $message";
    }
    throw CreationTransactionException(message: message);
  }

  final rAmt = pendingTx.amount();
  final rFee = pendingTx.fee();
  final rHash = pendingTx.txid('');
  final rHex = pendingTx.hex('');

  return PendingTransactionDescription(
    amount: rAmt,
    fee: rFee,
    hash: rHash,
    hex: rHex,
    pointerAddress: pendingTx.ffiAddress(),
  );
}

Future<PendingTransactionDescription> createTransactionMultDest({required List<MoneroOutput> outputs, required String paymentId, required int priorityRaw, int accountIndex = 0, List<String> preferredInputs = const []}) async {
  final dstAddrs = outputs.map((e) => e.address).toList();
  final amounts = outputs.map((e) => currentWallet!.amountFromString(e.amount)).toList();

  final waddr = currentWallet!.ffiAddress();

  // force reconnection in case the os killed the connection
  Isolate.run(() async {
    monero.Wallet_synchronized(Pointer.fromAddress(waddr));
  });

  final txptr = Pointer<Void>.fromAddress(await Isolate.run(() {
    return monero.Wallet_createTransactionMultDest(
      Pointer.fromAddress(waddr),
      dstAddr: dstAddrs,
      isSweepAll: false,
      amounts: amounts,
      mixinCount: 0,
      pendingTransactionPriority: priorityRaw,
      subaddr_account: accountIndex,
    ).address;
  }));

  final Wallet2PendingTransaction tx = MoneroPendingTransaction(txptr);

  if (tx.status() != 0) {
    throw CreationTransactionException(message: tx.errorString());
  }

  return PendingTransactionDescription(
    amount: tx.amount(),
    fee: tx.fee(),
    hash: tx.txid(''),
    hex: tx.hex(''),
    pointerAddress: tx.ffiAddress(),
  );
}

Future<String?> commitTransactionFromPointerAddress({required int address, required bool useUR}) => commitTransaction(tx: MoneroPendingTransaction(Pointer.fromAddress(address)), useUR: useUR);

Future<String?> commitTransaction({required Wallet2PendingTransaction tx, required bool useUR}) async {
  final txCommit = useUR
      ? tx.commitUR(120)
      : await Isolate.run(() {
          monero.PendingTransaction_commit(
            Pointer.fromAddress(tx.ffiAddress()),
            filename: '',
            overwrite: false,
          );
          return null;
        });

  String? error = (() {
    final status = tx.status();
    if (status == 0) {
      return null;
    }
    return tx.errorString();
  })();
  if (error == null) {
    error = (() {
      final status = currentWallet!.status();
      if (status == 0) {
        return null;
      }
      return currentWallet!.errorString();
    })();
  }
  if (error != null && error != "no tx keys found for this txid") {
    throw CreationTransactionException(message: error);
  }
  unawaited(() async {
    storeSync(force: true);
    await Future.delayed(Duration(seconds: 5));
    storeSync(force: true);
  }());
  return Future.value(txCommit);
}

class Transaction {
  final String displayLabel;
  late final String subaddressLabel = currentWallet!.getSubaddressLabel(
    accountIndex: accountIndex,
    addressIndex: addressIndex,
  );
  late final String address = getAddress(
    accountIndex: accountIndex,
    addressIndex: addressIndex,
  );
  late final List<String> addressList = List.generate(
      addressIndexList.length,
      (index) => getAddress(
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
  final Wallet2TransactionInfo txInfo;
  Transaction({
    required this.txInfo,
  })  : displayLabel = txInfo.label(),
        hash = txInfo.hash(),
        timeStamp = DateTime.fromMillisecondsSinceEpoch(
          txInfo.timestamp() * 1000,
        ),
        isSpend = txInfo.direction() == monero.TransactionInfo_Direction.Out.index,
        amount = txInfo.amount(),
        paymentId = txInfo.paymentId(),
        accountIndex = txInfo.subaddrAccount(),
        addressIndex = int.tryParse(txInfo.subaddrIndex().split(", ")[0]) ?? 0,
        addressIndexList = txInfo.subaddrIndex().split(", ").map((e) => int.tryParse(e) ?? 0).toList(),
        blockheight = txInfo.blockHeight(),
        confirmations = txInfo.confirmations(),
        fee = txInfo.fee(),
        description = txInfo.description(),
        key = getTxKey(txInfo.hash());

  Transaction.dummy({required this.displayLabel, required this.description, required this.fee, required this.confirmations, required this.blockheight, required this.accountIndex, required this.addressIndexList, required this.addressIndex, required this.paymentId, required this.amount, required this.isSpend, required this.hash, required this.key, required this.txInfo});
}
