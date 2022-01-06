mixin PendingTransaction {
  String get id;
  String get amountFormatted;
  String get feeFormatted;

  Future<void> commit();
}