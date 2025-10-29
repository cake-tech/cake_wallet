class BaseMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Base mnemonic has incorrect format. Mnemonic should contain 12 or 24 words separated by space.';
}
