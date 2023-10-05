import 'package:cw_core/pending_transaction.dart';
import 'package:cw_nano/nano_client.dart';
import 'package:cw_nano/nano_util.dart';

class PendingNanoTransaction with PendingTransaction {
  PendingNanoTransaction({
    required this.nanoClient,
    required this.amount,
    required this.id,
    required this.blocks,
  });

  final NanoClient nanoClient;
  final BigInt amount;
  final String id;
  final List<Map<String, String>> blocks;
  String hex = "unused";

  @override
  String get amountFormatted {
    final String amt = NanoUtil.getRawAsUsableString(amount.toString(), NanoUtil.rawPerNano);
    return amt;
  }

  String get accurateAmountFormatted {
    final String amt = NanoUtil.getRawAsUsableString(amount.toString(), NanoUtil.rawPerNano);
    final String acc = NanoUtil.getRawAccuracy(amount.toString(), NanoUtil.rawPerNano);
    return "$acc$amt";
  }

  @override
  String get feeFormatted => "0";

  @override
  Future<void> commit() async {
    for (var block in blocks) {
      await nanoClient.processBlock(block, "send");
    }
  }
}
