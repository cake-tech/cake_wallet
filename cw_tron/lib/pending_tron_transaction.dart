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
  String get feeFormatted => fee.toStringWithSymbol();

  @override
  String get feeFormattedValue => fee.toString();

  @override
  String get hex => bytesToHex(signedTransaction);

  @override
  String get id => '';
  
  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError();
  }
}
