import 'package:cw_core/amount/money.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:web3dart/crypto.dart';

class PendingTronTransaction with PendingTransaction {
  final Function sendTransaction;
  final List<int> signedTransaction;

  PendingTronTransaction({
    required this.sendTransaction,
    required this.signedTransaction,
    required this.fee,
    required this.amount,
    required this.id,
  });

  @override
  final Money amount;

  @override
  final Money fee;

  @override
  String get amountFormatted => amount.toString();

  @override
  Future<void> commit() async => await sendTransaction();

  @override
  String get hex => bytesToHex(signedTransaction);

  @override
  String id;

  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError();
  }
}
