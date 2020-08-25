mixin PendingTransaction {
  String get amountFormatted;
  String get feeFormatted;

  Future<void> commit();
}