import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;

class MnemonicBip39 {
  /// Generate bip39 mnemonic
  static String generate({int strength = 128}) => bip39.generateMnemonic(strength: strength);

  /// Create root seed from mnemonic
  static Uint8List toSeed(String mnemonic) => bip39.mnemonicToSeed(mnemonic);
}
