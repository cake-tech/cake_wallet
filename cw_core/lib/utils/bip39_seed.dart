import "dart:convert";
import "dart:typed_data";

import "package:blockchain_utils/blockchain_utils.dart";

Uint8List bip39MnemonicToSeed(String mnemonic, {String passphrase = ""}) =>
    Uint8List.fromList(QuickCrypto.pbkdf2DeriveKey(
      password: Uint8List.fromList(mnemonic.codeUnits),
      salt: utf8.encode("mnemonic$passphrase"),
      iterations: 2048,
    ));
