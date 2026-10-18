import "package:bip39/bip39.dart" as bip39;

class DecredMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      "Decred mnemonic has incorrect format. Mnemonic should be a valid BIP39 seed (12 or 24 words) or a native Decred seed (15 words).";
}

bool isValidDecredMnemonic(String mnemonic, {bool allowNativeSeed = true}) {
  if (bip39.validateMnemonic(mnemonic)) {
    return true;
  }
  if (!allowNativeSeed) {
    return false;
  }
  final wordCount = mnemonic.trim().split(RegExp(r"\s+")).where((word) => word.isNotEmpty).length;
  return wordCount == 15;
}

void validateDecredMnemonic(String mnemonic, {bool allowNativeSeed = true}) {
  if (!isValidDecredMnemonic(mnemonic, allowNativeSeed: allowNativeSeed)) {
    throw DecredMnemonicIsIncorrectException();
  }
}
