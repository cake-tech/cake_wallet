import 'package:cw_core/pending_transaction.dart';
import 'package:cw_xelis/xelis_formatting.dart';

class XelisPendingTransaction with PendingTransaction {
  XelisPendingTransaction(
      {
        required this.txid,
        required this.amount,
        required this.fee,
        required this.decimals,
        required this.send,
      });

  final String amount;
  final int fee;
  final String txid;
  final int decimals;
  final Future<void> Function() send;

  @override
  String get id => txid;

  @override
  String get amountFormatted => amount.toString();

  @override
  String get feeFormatted => XelisFormatter.formatAmount(fee, decimals: 8);

  @override
  String get hex => "";

  @override
  Future<void> commit() async {
    return send();
  }

  @override
  Future<String?> commitUR() {
    throw UnimplementedError();
  }
}
