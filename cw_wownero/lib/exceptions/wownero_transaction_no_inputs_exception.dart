class WowneroTransactionNoInputsException implements Exception {
  WowneroTransactionNoInputsException(this.inputsSize);

  int inputsSize;

  @override
  String toString() => 'Not enough inputs ($inputsSize) selected. Please select more under Coin Control';
}
