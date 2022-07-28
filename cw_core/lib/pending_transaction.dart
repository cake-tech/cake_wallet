mixin PendingTransaction {
  String get id;
  String get amountFormatted;
  String get feeFormatted;
  String get hex;

  Future<void> commit();
}