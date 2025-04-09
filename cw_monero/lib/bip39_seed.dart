import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:polyseed/polyseed.dart';

bool isBip39Seed(String mnemonic) => bip39.validateMnemonic(mnemonic);

String getBip39Seed() => bip39.generateMnemonic();

String getLegacySeedFromBip39(String mnemonic,
  {int accountIndex = 0, String passphrase = ""}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);

  final bip32KeyPair =
      bip32.BIP32.fromSeed(seed).derivePath("m/44'/128'/$accountIndex'/0/0");

  final spendKey = _reduceECKey(bip32KeyPair.privateKey!);

  return LegacySeedLang.getByEnglishName("English")
      .encodePhrase(spendKey.toHexString());
}

const _ed25519CurveOrder =
    "1000000000000000000000000000000014DEF9DEA2F79CD65812631A5CF5D3ED";

Uint8List _reduceECKey(Uint8List buffer) {
  final curveOrder = BigInt.parse(_ed25519CurveOrder, radix: 16);
  final bigNumber = _readBytes(buffer);

  var result = bigNumber % curveOrder;

  final resultBuffer = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    resultBuffer[i] = (result & BigInt.from(0xff)).toInt();
    result = result >> 8;
  }

  return resultBuffer;
}

/// Read BigInt from a little-endian Uint8List
/// From https://github.com/dart-lang/sdk/issues/32803#issuecomment-387405784
BigInt _readBytes(Uint8List bytes) {
  BigInt read(int start, int end) {
    if (end - start <= 4) {
      var result = 0;
      for (int i = end - 1; i >= start; i--) {
        result = result * 256 + bytes[i];
      }
      return BigInt.from(result);
    }
    final mid = start + ((end - start) >> 1);
    return read(start, mid) +
        read(mid, end) * (BigInt.one << ((mid - start) * 8));
  }

  return read(0, bytes.length);
}
