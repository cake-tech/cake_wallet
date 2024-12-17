class PendingChange {
  final String address;
  final String amount;

  PendingChange(this.address, this.amount);
}

mixin PendingTransaction {
  String get id;
  String get amountFormatted;
  String get feeFormatted;
  String? feeRate;
  String get hex;
  int? get outputCount => null;
  PendingChange? change;

  bool shouldCommitUR() => false;

  Future<void> commit();
  Future<String?> commitUR();
}
