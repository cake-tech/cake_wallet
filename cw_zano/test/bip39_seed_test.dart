import 'package:cw_zano/bip39_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Zano bip39 secret derivation", () {
    group("Test Wallet 1", () {
      final bip39Seed =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final expectedSecretDerivation =
          "bfafd1eb0e43da200c5c11537d355e458e7c326b3bc1b19f4546573d6bac9d0f";
      final expectedSecretDerivationWithPassphrase =
          "674ba1caeaf8a79e66a026858c78d4e565032953e98d39bdea12559bcae86a0c";

      test("Get secret derivation from bip39", () {
        final secretDerivation = getSecretDerivationFromBip39(bip39Seed);
        expect(secretDerivation, expectedSecretDerivation);
      });

      test("Get secret derivation from bip39 with passphrase", () {
        final secretDerivation =
            getSecretDerivationFromBip39(bip39Seed, passphrase: 'TREZOR');
        expect(secretDerivation, expectedSecretDerivationWithPassphrase);
      });
    });

    group("Test Wallet 2", () {
      final bip39Seed =
          'melt veteran patrol echo miss fat wrap apple crowd eyebrow weird boring';
      final expectedSecretDerivation =
          "8b2693e1d60b0431e3208762bc8a3f232890f50a3fea1e9605ec10a86afe1800";

      test("Get secret derivation from bip39", () {
        final secretDerivation = getSecretDerivationFromBip39(bip39Seed);
        expect(secretDerivation, expectedSecretDerivation);
      });
    });
  });
}
