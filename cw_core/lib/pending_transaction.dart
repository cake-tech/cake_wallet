mixin PendingTransaction {
  String get id;
  String get amountFormatted;
  String get feeFormatted;
  String get hex;
  int? get outputCount => null;

  Future<void> commit();
}