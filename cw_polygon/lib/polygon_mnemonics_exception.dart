class PolygonMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Polygon mnemonic has incorrect format. Mnemonic should contain 12 or 24 words separated by space.';
}
