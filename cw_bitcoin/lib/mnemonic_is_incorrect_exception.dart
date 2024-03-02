class BitcoinMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Bitcoin mnemonic has incorrect format. Mnemonic should contain 12 or 24 words separated by space.';
}

class LitecoinMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Litecoin mnemonic has incorrect format. Mnemonic should contain 24 words separated by space.';
}
