class BitcoinTransactionWrongBalanceException implements Exception {
  @override
  String toString() => 'Wrong balance. Not enough BTC on your balance.';
}