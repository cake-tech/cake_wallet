import 'package:cw_core/amount/money.dart';

class PendingChange {
  final String address;
  final BigInt amount;

  PendingChange(this.address, this.amount);
}

mixin PendingTransaction {
  String get id;

  Money get amount;
  Money get fee;

  String get amountFormatted;
  String get feeFormatted => fee.toStringWithSymbol(fractionalDigits: 8);
  String get feeFormattedValue => fee.toStringWithPrecision(fractionalDigits: 8);
  String? feeRate;
  String get hex;
  String? get evmTxHashFromRawHex => null;
  int? get outputCount => null;
  PendingChange? change;

  bool shouldCommitUR() => false;

  Future<void> commit();
  Future<Map<String, String>> commitUR();
}
