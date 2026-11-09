import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/utils/bip39_seed.dart';

class MnemonicBip39 {
  /// Generate bip39 mnemonic
  static String generate({int strength = 128}) => bip39.generateMnemonic(strength: strength);

  /// Create root seed from mnemonic
  static Uint8List toSeed(String mnemonic, {String? passphrase}) =>
      bip39MnemonicToSeed(mnemonic, passphrase: passphrase ?? '');
}
