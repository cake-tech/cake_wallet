import 'package:cake_wallet/bitcoin/bitcoin_commit_transaction_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';
import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/bitcoin/electrum_transaction_info.dart';
import 'package:cake_wallet/entities/transaction_direction.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

class PendingBitcoinTransaction with PendingTransaction {
  PendingBitcoinTransaction(this._tx, this.type,
      {@required this.electrumClient,
      @required this.amount,
      @required this.fee})
      : _listeners = <void Function(ElectrumTransactionInfo transaction)>[];

  final WalletType type;
  final bitcoin.Transaction _tx;
  final ElectrumClient electrumClient;
  final int amount;
  final int fee;

  @override
  String get id => _tx.getId();

  @override
  String get amountFormatted => bitcoinAmountToString(amount: amount);

  @override
  String get feeFormatted => bitcoinAmountToString(amount: fee);

  final List<void Function(ElectrumTransactionInfo transaction)> _listeners;

  @override
  Future<void> commit() async {
    final result =
      await electrumClient.broadcastTransaction(transactionRaw: _tx.toHex());

    if (result.isEmpty) {
      throw BitcoinCommitTransactionException();
    }

    _listeners?.forEach((listener) => listener(transactionInfo()));
  }

  void addListener(
          void Function(ElectrumTransactionInfo transaction) listener) =>
      _listeners.add(listener);

  ElectrumTransactionInfo transactionInfo() => ElectrumTransactionInfo(type,
      id: id,
      height: 0,
      amount: amount,
      direction: TransactionDirection.outgoing,
      date: DateTime.now(),
      isPending: true,
      confirmations: 0,
      fee: fee);
}
