import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_nano/nano_client.dart';
import 'package:cw_nano/nano_transaction_info.dart';
import 'package:cw_nano/nano_util.dart';

class PendingNanoTransaction with PendingTransaction {
  PendingNanoTransaction({
    required this.nanoClient,
    required this.amount,
    required this.fee,
    required this.id,
  });

  final NanoClient nanoClient;
  final BigInt amount;
  final int fee;
  final String id;
  String hex = "unused";

  // @override
  // String get id => id;

  // @override
  // String get hex => _tx.toHex();

  @override
  String get amountFormatted =>
      NanoUtil.getRawAsUsableString(amount.toString(), NanoUtil.rawPerNano);

  @override
  String get feeFormatted => "0";

  // final List<void Function(ElectrumTransactionInfo transaction)> _listeners;

  @override
  Future<void> commit() async {
    // final result =
    //   await electrumClient.broadcastTransaction(transactionRaw: _tx.toHex());

    // if (result.isEmpty) {
    //   throw BitcoinCommitTransactionException();
    // }

    // _listeners?.forEach((listener) => listener(transactionInfo()));
  }

  // void addListener(
  //         void Function(ElectrumTransactionInfo transaction) listener) =>
  //     _listeners.add(listener);

  // ElectrumTransactionInfo transactionInfo() => ElectrumTransactionInfo(type,
  //     id: id,
  //     height: 0,
  //     amount: amount,
  //     direction: TransactionDirection.outgoing,
  //     date: DateTime.now(),
  //     isPending: true,
  //     confirmations: 0,
  //     fee: fee);
}
