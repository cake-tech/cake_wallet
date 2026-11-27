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

  test("hdMnemonicToSeed applies the BIP39 passphrase", () async {
    expect(
      await NanoMnemomics.hdMnemonicToSeed(
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
        passphrase: "TREZOR",
      ),
      "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04",
    );
    for (var i = 0; i < 20; i++) {
      final mnemonic = bip39.generateMnemonic(strength: i.isEven ? 128 : 256);
      final passphrase = "pass phrase $i ✓";
      expect(
        await NanoMnemomics.hdMnemonicToSeed(mnemonic, passphrase: passphrase),
        bip39.mnemonicToSeedHex(mnemonic, passphrase: passphrase),
      );
    }
  });
}
