String calculateFiatAmount({double price, String cryptoAmount}) {
  if (price == null || cryptoAmount == null) {
    return '0.00';
  }

  final _amount = double.parse(cryptoAmount);
  final _result = price * _amount;
  final result = _result < 0 ? _result * -1 : _result;

  if (result == 0.0) {
    return '0.00';
  }

  return result > 0.01 ? result.toStringAsFixed(2) : '< 0.01';
}
