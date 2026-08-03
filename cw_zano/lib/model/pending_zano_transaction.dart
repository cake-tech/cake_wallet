import 'package:cw_core/amount/money.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_zano/api/model/destination.dart';
import 'package:cw_zano/api/model/transfer_result.dart';
import 'package:cw_zano/zano_wallet.dart';

class PendingZanoTransaction with PendingTransaction {
  PendingZanoTransaction({
    required this.zanoWallet,
    required this.destinations,
    required this.fee,
    required this.comment,
    required this.assetId,
    required this.amount,
  });

  final ZanoWalletBase zanoWallet;
  final List<Destination> destinations;
  final String comment;
  final String assetId;

  @override
  final Money amount;

  @override
  final Money fee;

  @override
  String get id => transferResult?.txHash ?? '';

  @override
  String get hex => '';

  @override
  String get amountFormatted => amount.toString();

  TransferResult? transferResult;

  @override
  Future<void> commit() async {
    transferResult = await zanoWallet.transfer(destinations, fee.amount, comment);
    zanoWallet.fetchTransactions();
  }

  @override
  Future<Map<String, String>> commitUR() => throw UnimplementedError();
}
