class BitcoinMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Bitcoin mnemonic has incorrect format. Mnemonic should contain 12 words separated by space.';
}
