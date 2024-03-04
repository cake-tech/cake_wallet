import 'package:cw_bitcoin/bitcoin_commit_transaction_exception.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';

class PendingBitcoinTransaction with PendingTransaction {
  PendingBitcoinTransaction(this._tx, this.type,
      {required this.electrumClient, required this.amount, required this.fee, this.network})
      : _listeners = <void Function(ElectrumTransactionInfo transaction)>[];

  final WalletType type;
  final BtcTransaction _tx;
  final ElectrumClient electrumClient;
  final int amount;
  final int fee;
  final BasedUtxoNetwork? network;

  @override
  String get id => _tx.txId();

  @override
  String get hex => _tx.serialize();

  @override
  String get amountFormatted => bitcoinAmountToString(amount: amount);

  @override
  String get feeFormatted => bitcoinAmountToString(amount: fee);

  final List<void Function(ElectrumTransactionInfo transaction)> _listeners;

  @override
  Future<void> commit() async {
    final result = await electrumClient.broadcastTransaction(transactionRaw: hex, network: network);

    if (result.isEmpty) {
      throw BitcoinCommitTransactionException();
    }

    _listeners.forEach((listener) => listener(transactionInfo()));
  }

  void addListener(void Function(ElectrumTransactionInfo transaction) listener) =>
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
