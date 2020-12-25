import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/entities/transaction_direction.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';

class PendingBitcoinTransaction with PendingTransaction {
  PendingBitcoinTransaction(this._tx,
      {@required this.eclient, @required this.amount, @required this.fee})
      : _listeners = <void Function(BitcoinTransactionInfo transaction)>[];

  final bitcoin.Transaction _tx;
  final ElectrumClient eclient;
  final int amount;
  final int fee;

  @override
  String get id => _tx.getId();

  @override
  String get amountFormatted => bitcoinAmountToString(amount: amount);

  @override
  String get feeFormatted => bitcoinAmountToString(amount: fee);

  final List<void Function(BitcoinTransactionInfo transaction)> _listeners;

  @override
  Future<void> commit() async {
    await eclient.broadcastTransaction(transactionRaw: _tx.toHex());
    _listeners?.forEach((listener) => listener(transactionInfo()));
  }

  void addListener(
          void Function(BitcoinTransactionInfo transaction) listener) =>
      _listeners.add(listener);

  BitcoinTransactionInfo transactionInfo() => BitcoinTransactionInfo(
      id: id,
      height: 0,
      amount: amount,
      direction: TransactionDirection.outgoing,
      date: DateTime.now(),
      isPending: true,
      confirmations: 0);
}
