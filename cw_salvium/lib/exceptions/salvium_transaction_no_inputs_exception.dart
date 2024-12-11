class SalviumTransactionNoInputsException implements Exception {
  SalviumTransactionNoInputsException(this.inputsSize);

  int inputsSize;

  @override
  String toString() =>
      'Not enough inputs ($inputsSize) selected. Please select more under Coin Control';
}
