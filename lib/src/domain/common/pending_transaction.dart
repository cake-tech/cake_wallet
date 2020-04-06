import 'package:flutter/foundation.dart';
import 'package:cw_monero/transaction_history.dart' as transaction_history;
import 'package:cw_monero/structs/pending_transaction.dart';
import 'package:cake_wallet/src/domain/monero/monero_amount_format.dart';
import 'package:cake_wallet/src/domain/bitcoin/bitcoin_amount_format.dart';
import 'package:flutter/services.dart';

class PendingTransaction {
  PendingTransaction(
      {@required this.amount, @required this.fee, @required this.hash});

  PendingTransaction.fromTransactionDescription(
      PendingTransactionDescription transactionDescription)
      : amount = moneroAmountToString(amount: transactionDescription.amount),
        fee = moneroAmountToString(amount: transactionDescription.fee),
        hash = transactionDescription.hash,
        _pointerAddress = transactionDescription.pointerAddress;

  PendingTransaction.fromBitcoinTransaction(Map<String,String> map)
      : amount = bitcoinAmountToString(amount: int.parse(map['amount'])),
        fee = bitcoinAmountToString(amount: int.parse(map['fee'])),
        hash = map['hash'];

  final String amount;
  final String fee;
  final String hash;

  int _pointerAddress;

  Future<void> commit() async => transaction_history
      .commitTransactionFromPointerAddress(address: _pointerAddress);

  Future<void> commitBitcoinTransaction() async {
    final bitcoinWalletChannel =
    MethodChannel('com.cakewallet.cake_wallet/bitcoin-wallet');
    await bitcoinWalletChannel.invokeMethod<void>('commitTransaction');
  }
}
