mixin PendingTransaction {
  String get id;
  String get amountFormatted;
  String get feeFormatted;
  String? feeRate;
  String get hex;
  int? get outputCount => null;

  bool shouldCommitUR() => false;

  Future<void> commit();
  Future<String?> commitUR();
}
