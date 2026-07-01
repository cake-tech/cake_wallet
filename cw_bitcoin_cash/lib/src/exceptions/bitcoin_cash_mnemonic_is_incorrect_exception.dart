class BitcoinCashMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Bitcoin Cash mnemonic has incorrect format. Mnemonic should contain 12 or 24 words separated by space.';
}
