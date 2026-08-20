import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip39/src/wordlists/english.dart' as bip39_english;

bool isBip39Seed(String mnemonic) => bip39.validateMnemonic(mnemonic);

List<String> get bip39EnglishWords => List<String>.from(bip39_english.WORDLIST);

String generateBip39Mnemonic({int strength = 128}) =>
    bip39.generateMnemonic(strength: strength);

String getSecretDerivationFromBip39(String mnemonic, {String passphrase = ''}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  return Uint8List.fromList(seed.sublist(0, 32)).toHexString();
}

extension on Uint8List {
  String toHexString() =>
      map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
