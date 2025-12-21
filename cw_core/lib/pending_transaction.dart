class PendingChange {
  final String address;
  final BigInt amount;

  PendingChange(this.address, this.amount);
}

mixin PendingTransaction {
  String get id;
  String get amountFormatted;
  String get feeFormatted;
  String get feeFormattedValue;
  String? feeRate;
  String get hex;
  String? get evmTxHashFromRawHex => null;
  int? get outputCount => null;
  PendingChange? change;

  bool shouldCommitUR() => false;

  Future<void> commit();
  Future<Map<String, String>> commitUR();
}
