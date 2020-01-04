import 'package:flutter/foundation.dart';
import 'package:cw_monero/transaction_history.dart' as transactionHistory;
import 'package:cw_monero/structs/pending_transaction.dart';
import 'package:cake_wallet/src/domain/monero/monero_amount_format.dart';

class PendingTransaction {
  final String amount;
  final String fee;
  final String hash;

  int _pointerAddress;

  PendingTransaction(
      {@required this.amount, @required this.fee, @required this.hash});

  PendingTransaction.fromTransactionDescription(
      PendingTransactionDescription transactionDescription)
      : amount = moneroAmountToString(amount: transactionDescription.amount),
        fee = moneroAmountToString(amount: transactionDescription.fee),
        hash = transactionDescription.hash,
        _pointerAddress = transactionDescription.pointerAddress;

  Future commit() async => transactionHistory
      .commitTransactionFromPointerAddress(address: _pointerAddress);
}
