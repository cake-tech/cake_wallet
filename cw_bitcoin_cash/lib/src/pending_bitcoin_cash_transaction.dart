import 'package:cw_bitcoin/bitcoin_commit_transaction_exception.dart';
import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';

class PendingBitcoinCashTransaction with PendingTransaction {
  PendingBitcoinCashTransaction(this._tx, this.type,
      {required this.electrumClient,
      required this.amount,
      required this.fee})
      : _listeners = <void Function(ElectrumTransactionInfo transaction)>[];

  final WalletType type;
  final bitbox.Transaction _tx;
  final ElectrumClient electrumClient;
  final int amount;
  final int fee;

  @override
  String get id => _tx.getId();

  @override
  String get hex => _tx.toHex();

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
