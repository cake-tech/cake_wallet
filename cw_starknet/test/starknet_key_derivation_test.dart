import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:starknet/starknet.dart';

/// Re-implementation of the wallet's key derivation for testing
/// without needing Flutter/Hive dependencies.
Felt deriveStarkPrivateKey(String mnemonic, {String? passphrase}) {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase ?? '');

  final hmac = crypto_lib.Hmac(crypto_lib.sha256, seed);
  final derivationData = utf8.encode('Starknet key derivation');
  var derived = hmac.convert(derivationData).bytes;

  for (int i = 0; i < 10000; i++) {
    final candidate = BigInt.parse(HEX.encode(derived), radix: 16) % starkN;
    if (candidate > BigInt.zero) {
      return Felt(candidate);
    }
    final nextHmac = crypto_lib.Hmac(crypto_lib.sha256, derived);
    derived = nextHmac.convert([i]).bytes;
  }

  throw Exception('Failed to derive valid Stark private key');
}

Felt computeAccountAddress(Felt publicKey) {
  final classHash = Felt.fromHex(
      '0x01d1777db36cdd06dd62cfde77b1b6ae06412af95d57a13dc40ac77b8a702381');

  return Felt(calculateContractAddress(
    deployerAddress: BigInt.zero,
    salt: publicKey.value,
    classHash: classHash.value,
    constructorCalldata: [publicKey.value],
  ));
}

void main() {
  const testMnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  group('Stark key derivation', () {
    test('derives a valid private key from mnemonic', () {
      final privateKey = deriveStarkPrivateKey(testMnemonic);

      // Key must be > 0 and < starkN
      expect(privateKey.value > BigInt.zero, true);
      expect(privateKey.value < starkN, true);
    });

    test('derivation is deterministic', () {
      final key1 = deriveStarkPrivateKey(testMnemonic);
      final key2 = deriveStarkPrivateKey(testMnemonic);

      expect(key1, equals(key2));
    });

    test('different mnemonics produce different keys', () {
      final key1 = deriveStarkPrivateKey(testMnemonic);
      final key2 = deriveStarkPrivateKey(
          'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong');

      expect(key1, isNot(equals(key2)));
    });

    test('passphrase changes the derived key', () {
      final key1 = deriveStarkPrivateKey(testMnemonic);
      final key2 =
          deriveStarkPrivateKey(testMnemonic, passphrase: 'my-passphrase');

      expect(key1, isNot(equals(key2)));
    });

    test('empty passphrase equals no passphrase', () {
      final key1 = deriveStarkPrivateKey(testMnemonic);
      final key2 = deriveStarkPrivateKey(testMnemonic, passphrase: '');

      expect(key1, equals(key2));
    });
  });

  group('Public key derivation', () {
    test('derives public key from private key', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);
      final publicKey = await signer.getPublicKey();

      // Public key must be valid Felt
      expect(publicKey.value > BigInt.zero, true);
      expect(publicKey.value < Felt.prime, true);
    });

    test('public key derivation is deterministic', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);

      final signer1 = StarkPrivateKeySigner(privateKey);
      final signer2 = StarkPrivateKeySigner(privateKey);

      final pub1 = await signer1.getPublicKey();
      final pub2 = await signer2.getPublicKey();

      expect(pub1, equals(pub2));
    });
  });

  group('Account address computation', () {
    test('computes a valid account address', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);
      final publicKey = await signer.getPublicKey();
      final address = computeAccountAddress(publicKey);

      // Address must be a valid Felt
      expect(address.value > BigInt.zero, true);
      expect(address.value < Felt.prime, true);

      // Address hex should start with 0x
      expect(address.toHex().startsWith('0x'), true);
    });

    test('address computation is deterministic', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);
      final publicKey = await signer.getPublicKey();

      final addr1 = computeAccountAddress(publicKey);
      final addr2 = computeAccountAddress(publicKey);

      expect(addr1, equals(addr2));
    });

    test('different keys produce different addresses', () async {
      final key1 = deriveStarkPrivateKey(testMnemonic);
      final key2 = deriveStarkPrivateKey(
          'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong');

      final signer1 = StarkPrivateKeySigner(key1);
      final signer2 = StarkPrivateKeySigner(key2);

      final pub1 = await signer1.getPublicKey();
      final pub2 = await signer2.getPublicKey();

      final addr1 = computeAccountAddress(pub1);
      final addr2 = computeAccountAddress(pub2);

      expect(addr1, isNot(equals(addr2)));
    });
  });

  group('Full mnemonic-to-address pipeline', () {
    test('consistent end-to-end derivation', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);
      final publicKey = await signer.getPublicKey();
      final address = computeAccountAddress(publicKey);

      // Run the whole pipeline again
      final privateKey2 = deriveStarkPrivateKey(testMnemonic);
      final signer2 = StarkPrivateKeySigner(privateKey2);
      final publicKey2 = await signer2.getPublicKey();
      final address2 = computeAccountAddress(publicKey2);

      expect(privateKey, equals(privateKey2));
      expect(publicKey, equals(publicKey2));
      expect(address, equals(address2));
    });
  });

  group('Signing', () {
    test('signs a message hash and returns valid signature', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);

      final messageHash = Felt.fromHex('0xdeadbeef');
      final signature = await signer.signHash(messageHash);

      expect(signature.length, 2);
      // r and s must be valid Felts
      expect(signature[0].value > BigInt.zero, true);
      expect(signature[1].value > BigInt.zero, true);
    });

    test('signing is deterministic (RFC-6979)', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);

      final messageHash = Felt.fromHex('0xcafebabe');
      final sig1 = await signer.signHash(messageHash);
      final sig2 = await signer.signHash(messageHash);

      expect(sig1[0], equals(sig2[0]));
      expect(sig1[1], equals(sig2[1]));
    });

    test('different messages produce different signatures', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);

      final sig1 = await signer.signHash(Felt.fromHex('0x1'));
      final sig2 = await signer.signHash(Felt.fromHex('0x2'));

      expect(sig1[0] == sig2[0] && sig1[1] == sig2[1], false);
    });

    test('signature can be verified', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);
      final publicKey = await signer.getPublicKey();

      final messageHash = Felt.fromHex('0xdeadbeef');
      final signature = await signer.signHash(messageHash);

      final isValid = verify(
        publicKey.value,
        messageHash.value,
        signature[0].value,
        signature[1].value,
      );
      expect(isValid, true);
    });

    test('verification fails with wrong public key', () async {
      final privateKey = deriveStarkPrivateKey(testMnemonic);
      final signer = StarkPrivateKeySigner(privateKey);

      final wrongKey = deriveStarkPrivateKey(
          'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong');
      final wrongSigner = StarkPrivateKeySigner(wrongKey);
      final wrongPubKey = await wrongSigner.getPublicKey();

      final messageHash = Felt.fromHex('0xdeadbeef');
      final signature = await signer.signHash(messageHash);

      final isValid = verify(
        wrongPubKey.value,
        messageHash.value,
        signature[0].value,
        signature[1].value,
      );
      expect(isValid, false);
    });
  });
}
