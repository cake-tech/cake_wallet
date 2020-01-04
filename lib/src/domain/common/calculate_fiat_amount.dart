String calculateFiatAmount({double price, String cryptoAmount}) {
  if (price == null || cryptoAmount == null) {
    return '0.00';
  }

  final _amount = double.parse(cryptoAmount);
  final result = price * _amount;

  if (result == 0.0) {
    return '0.00';
  }

  return result > 0.01 ? result.toStringAsFixed(2) : '< 0.01';
}