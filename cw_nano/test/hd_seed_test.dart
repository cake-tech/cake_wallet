import "package:bip39/bip39.dart" as bip39;
import "package:cw_nano/nano_mnemonic.dart";
import "package:flutter_test/flutter_test.dart";
import "package:nanoutil/nanoutil.dart" show NanoDerivations;

void main() {
  test("hdMnemonicToSeed matches nanoutil", () async {
    for (var i = 0; i < 20; i++) {
      final mnemonic = bip39.generateMnemonic(strength: i.isEven ? 128 : 256);
      expect(
        await NanoMnemomics.hdMnemonicToSeed(mnemonic),
        await NanoDerivations.hdMnemonicListToSeed(mnemonic.split(" ")),
      );
    }
  });
}
