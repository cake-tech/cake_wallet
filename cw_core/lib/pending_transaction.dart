mixin PendingTransaction {
  String get id;
  String get amountFormatted;
  String get feeFormatted;
  String? feeRate;
  String get hex;

  Future<void> commit();
}
