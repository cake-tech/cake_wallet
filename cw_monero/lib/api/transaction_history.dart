
import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_monero/api/monero_output.dart';
import 'package:cw_monero/api/structs/pending_transaction.dart';
import 'package:monero/monero.dart' as monero;


String getTxKey(String txId) {
  return monero.Wallet_getTxKey(wptr!, txid: txId);
}

monero.TransactionHistory? txhistory;

void refreshTransactions() {
  txhistory = monero.Wallet_history(wptr!);
  monero.TransactionHistory_refresh(txhistory!);
}

int countOfTransactions() => monero.TransactionHistory_count(txhistory!);

List<Transaction> getAllTransactions() {
  final size = countOfTransactions();

  return List.generate(size, (index) => Transaction(txInfo: monero.TransactionHistory_transaction(txhistory!, index: index)));
}

// TODO(mrcyjanek): ...
Transaction getTransaction(String txId) {
  return Transaction(txInfo: monero.TransactionHistory_transactionById(txhistory!, txid: txId));
}

PendingTransactionDescription createTransactionSync(
    {required String address,
    required String paymentId,
    required int priorityRaw,
    String? amount,
    int accountIndex = 0,
    List<String> preferredInputs = const []}) {

  final amt = amount == null ? 0 : monero.Wallet_amountFromString(amount);
  final pendingTx = monero.Wallet_createTransaction(
    wptr!,
    dst_addr: address,
    payment_id: paymentId,
    amount: amt,
    mixin_count: 1,
    pendingTransactionPriority: priorityRaw,
    subaddr_account: accountIndex,
    preferredInputs: preferredInputs,
  );
  final String? error = (() {
    final status = monero.Wallet_status(wptr!);
    if (status == 0) {
      return null;
    }
    return monero.Wallet_errorString(wptr!);
  })();

  if (error != null) {
    final message = error;
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
  // final int size = outputs.length;
  // final List<Pointer<Utf8>> addressesPointers =
  //     outputs.map((output) => output.address.toNativeUtf8()).toList();
  // final Pointer<Pointer<Utf8>> addressesPointerPointer = calloc(size);
  // final List<Pointer<Utf8>> amountsPointers =
  //     outputs.map((output) => output.amount.toNativeUtf8()).toList();
  // final Pointer<Pointer<Utf8>> amountsPointerPointer = calloc(size);

  // for (int i = 0; i < size; i++) {
  //   addressesPointerPointer[i] = addressesPointers[i];
  //   amountsPointerPointer[i] = amountsPointers[i];
  // }

  // final int preferredInputsSize = preferredInputs.length;
  // final List<Pointer<Utf8>> preferredInputsPointers =
  //     preferredInputs.map((output) => output.toNativeUtf8()).toList();
  // final Pointer<Pointer<Utf8>> preferredInputsPointerPointer = calloc(preferredInputsSize);

  // for (int i = 0; i < preferredInputsSize; i++) {
  //   preferredInputsPointerPointer[i] = preferredInputsPointers[i];
  // }

  // final paymentIdPointer = paymentId.toNativeUtf8();
  // final errorMessagePointer = calloc<Utf8Box>();
  // final pendingTransactionRawPointer = calloc<PendingTransactionRaw>();
  // final created = transactionCreateMultDestNative(
  //         addressesPointerPointer,
  //         paymentIdPointer,
  //         amountsPointerPointer,
  //         size,
  //         priorityRaw,
  //         accountIndex,
  //         preferredInputsPointerPointer,
  //         preferredInputsSize,
  //         errorMessagePointer,
  //         pendingTransactionRawPointer) !=
  //     0;

  // calloc.free(addressesPointerPointer);
  // calloc.free(amountsPointerPointer);
  // calloc.free(preferredInputsPointerPointer);

  // addressesPointers.forEach((element) => calloc.free(element));
  // amountsPointers.forEach((element) => calloc.free(element));
  // preferredInputsPointers.forEach((element) => calloc.free(element));

  // calloc.free(paymentIdPointer);

  // if (!created) {
  //   final message = errorMessagePointer.ref.getValue();
  //   calloc.free(errorMessagePointer);
  //   throw CreationTransactionException(message: message);
  // }

  // return PendingTransactionDescription(
  //     amount: pendingTransactionRawPointer.ref.amount,
  //     fee: pendingTransactionRawPointer.ref.fee,
  //     hash: pendingTransactionRawPointer.ref.getHash(),
  //     hex: pendingTransactionRawPointer.ref.getHex(),
  //     txKey: pendingTransactionRawPointer.ref.getKey(),
  //     pointerAddress: pendingTransactionRawPointer.address);
  throw CreationTransactionException(message: "Unimplemented in monero_c");
}

void commitTransactionFromPointerAddress({required int address}) =>
    commitTransaction(transactionPointer: monero.PendingTransaction.fromAddress(address));

void commitTransaction({required monero.PendingTransaction transactionPointer}) {
  
  final txCommit = monero.PendingTransaction_commit(transactionPointer, filename: '', overwrite: false);
  final status = monero.PendingTransaction_status(transactionPointer.cast());

  final String? error = (() {
    final status = monero.Wallet_status(wptr!);
    if (status == 0) {
      return null;
    }
    return monero.Wallet_errorString(wptr!);
  })();
  
  if (error != null) {
    throw CreationTransactionException(message: error);
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
  String subaddressLabel = monero.Wallet_getSubaddressLabel(wptr!, accountIndex: 0, addressIndex: 0);
  late final String address = monero.Wallet_address(
    wptr!,
    accountIndex: 0,
    addressIndex: 0,
  );
  final String description;
  final int fee;
  final int confirmations;
  late final bool isPending = confirmations < 10;
  final int blockheight;
  final int accountIndex;
  final String paymentId;
  final int amount;
  final bool isSpend;
  late DateTime timeStamp;
  late final bool isConfirmed = !isPending;
  final String hash;

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
      "paymentId": paymentId,
      "amount": amount,
      "isSpend": isSpend,
      "timeStamp": timeStamp.toIso8601String(),
      "isConfirmed": isConfirmed,
      "hash": hash,
    };
  }

  // S finalubAddress? subAddress;
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
        blockheight = monero.TransactionInfo_blockHeight(txInfo),
        confirmations = monero.TransactionInfo_confirmations(txInfo),
        fee = monero.TransactionInfo_fee(txInfo),
        description = monero.TransactionInfo_description(txInfo);
}