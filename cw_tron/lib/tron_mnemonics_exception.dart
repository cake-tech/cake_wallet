class TronMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Tron mnemonic has incorrect format. Mnemonic should contain 12 or 24 words separated by space.';
}
