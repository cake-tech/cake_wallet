import "package:cw_bitcoin/lightning/spark_conversion.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/pending_transaction.dart";

class PendingLightningTransaction with PendingTransaction {
  PendingLightningTransaction({
    required this.id,
    required this.amount,
    required this.fee,
    required this.commitOverride,
    this.isSendAll = false,
    this.conversion,
    this.isOnChain = false,
  });

  final bool isSendAll;

  /// The Stable Balance conversion the SDK added to fund this send, if the sats balance was short.
  final StableBalanceSendConversion? conversion;

  /// Paid to a Bitcoin address (a cooperative exit) rather than over Lightning or as a Spark
  /// transfer.
  final bool isOnChain;

  Future<String> Function() commitOverride;
  final List<void Function()> _listeners = [];

  @override
  String id;

  @override
  final Money amount;

  @override
  final Money fee;

  @override
  String get hex => "";

  @override
  String get amountFormatted => amount.toString();

  @override
  int? get outputCount => 1;

  @override
  Future<void> commit() async {
    id = await commitOverride.call();
    _listeners.forEach((e) => e.call());
  }

  @override
  bool shouldCommitUR() => false;

  @override
  Future<Map<String, String>> commitUR() => throw UnimplementedError();

  void addListener(void Function() listener) => _listeners.add(listener);
}
