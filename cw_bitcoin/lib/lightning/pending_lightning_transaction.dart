import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/pending_transaction.dart';

class PendingLightningTransaction with PendingTransaction {
  PendingLightningTransaction({
    required this.id,
    required this.amount,
    required this.fee,
    this.isSendAll = false,
    required this.commitOverride,
  });

  final int amount;
  final int fee;
  final bool isSendAll;
  Future<void> Function() commitOverride;

  @override
  final String id;

  @override
  String get hex => "";

  @override
  String get amountFormatted => bitcoinAmountToString(amount: amount);

  @override
  String get feeFormatted => "$feeFormattedValue BTC";

  @override
  String get feeFormattedValue => bitcoinAmountToString(amount: fee);

  @override
  int? get outputCount => 1;

  @override
  Future<void> commit() => commitOverride.call();

  @override
  bool shouldCommitUR() => false;

  @override
  Future<Map<String, String>> commitUR() => throw UnimplementedError();
}
