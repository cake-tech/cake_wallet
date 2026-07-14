import 'package:cw_core/amount/money.dart';
import 'package:cw_core/pending_transaction.dart';

class PendingLightningTransaction with PendingTransaction {
  PendingLightningTransaction({
    required this.id,
    required this.amount,
    required this.fee,
    this.isSendAll = false,
    required this.commitOverride,
  });

  final bool isSendAll;
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
