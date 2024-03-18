class EthereumMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Ethereum mnemonic has incorrect format. Mnemonic should contain 12 or 24 words separated by space.';
}
