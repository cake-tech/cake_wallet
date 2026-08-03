import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_nano/nano_client.dart';

class PendingNanoTransaction with PendingTransaction {
  PendingNanoTransaction({
    required this.nanoClient,
    required this.amount,
    required this.id,
    required this.blocks,
  });

  final NanoClient nanoClient;
  final String id;
  final List<Map<String, String>> blocks;
  String hex = "unused";

  @override
  final Money amount;

  @override
  String get amountFormatted => amount.toString();

  @override
  Money get fee => Money.zero(CryptoCurrency.nano);

  @override
  Future<void> commit() async {
    for (final block in blocks) {
      await nanoClient.processBlock(block, "send");
    }
  }

  @override
  Future<Map<String, String>> commitUR() => throw UnimplementedError();
}
