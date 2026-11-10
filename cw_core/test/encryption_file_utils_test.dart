import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cake_backup/backup.dart' as cwb;
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/key.dart';
import 'package:cw_core/utils/file.dart' as encrypted_file;
import 'package:cw_core/wallet_keys_file.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('cw_enc_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  String path([String name = 'wallet.json']) => '${tmpDir.path}/$name';

  const walletJson = '{"mnemonic":"abandon ability able","privateKey":null}';

  group('XChaCha20 round-trip', () {
    test('writes and reads JSON with a generated high-entropy password', () async {
      final password = generateKey();
      await encrypted_file.write(
        path: path(),
        password: password,
        data: walletJson,
        highEntropyPassphrase: true,
      );

      expect(await encrypted_file.read(path: path(), password: password), walletJson);
      expect(File('${path()}.tmp').existsSync(), isFalse);
    });

    test('uses high-entropy (v3) vs low-entropy (v2) version bytes', () async {
      final password = generateKey();

      await encrypted_file.write(
        path: path('high'),
        password: password,
        data: walletJson,
        highEntropyPassphrase: true,
      );
      expect(File(path('high')).readAsBytesSync().first, cwb.highEntropyVersion);

      await encrypted_file.write(
        path: path('low'),
        password: password,
        data: walletJson,
        highEntropyPassphrase: false,
      );
      expect(File(path('low')).readAsBytesSync().first, cwb.lowEntropyVersion);

      expect(await encrypted_file.read(path: path('high'), password: password), walletJson);
      expect(await encrypted_file.read(path: path('low'), password: password), walletJson);
    });

    test('read ignores highEntropyPassphrase because version is in the file', () async {
      final password = generateKey();
      await encrypted_file.write(
        path: path(),
        password: password,
        data: walletJson,
        highEntropyPassphrase: true,
      );

      expect(
        await encrypted_file.read(
          path: path(),
          password: password,
          highEntropyPassphrase: false,
        ),
        walletJson,
      );
    });

    test('round-trips UTF-8 JSON with non-ASCII characters', () async {
      final password = generateKey();
      const data = '{"name":"Café","mnemonic":"abandon"}';
      await encrypted_file.write(
        path: path(),
        password: password,
        data: data,
        highEntropyPassphrase: true,
      );

      expect(await encrypted_file.read(path: path(), password: password), data);
    });

    test('wrong password does not fall back to Salsa20 or rewrite the file', () async {
      final password = generateKey();
      await encrypted_file.write(
        path: path(),
        password: password,
        data: walletJson,
        highEntropyPassphrase: true,
      );
      final before = File(path()).readAsBytesSync();

      await expectLater(
        encrypted_file.read(path: path(), password: generateKey()),
        throwsA(anything),
      );
      expect(File(path()).readAsBytesSync(), before);
    });

    test('corrupt XChaCha20 blob is not treated as a legacy Salsa20 file', () async {
      final password = generateKey();
      await encrypted_file.write(
        path: path(),
        password: password,
        data: walletJson,
        highEntropyPassphrase: true,
      );
      final bytes = File(path()).readAsBytesSync();
      bytes[bytes.length - 1] = bytes[bytes.length - 1] ^ 0xFF;
      File(path()).writeAsBytesSync(bytes);

      await expectLater(
        encrypted_file.read(path: path(), password: password),
        throwsA(anything),
      );
      expect(File(path()).readAsBytesSync().first, cwb.highEntropyVersion);
    });
  });

  group('encryptionFileUtilsFor', () {
    test('isDirect=false (generated password) writes high-entropy v3', () async {
      final password = generateKey();
      final encryption = encryptionFileUtilsFor(false);
      await encryption.write(path: path(), password: password, data: walletJson);

      expect(File(path()).readAsBytesSync().first, cwb.highEntropyVersion);
      expect(await encryption.read(path: path(), password: password), walletJson);
    });

    test('isDirect=true (user password) writes low-entropy v2', () async {
      const password = 'user-chosen-passphrase';
      final encryption = encryptionFileUtilsFor(true);
      await encryption.write(path: path(), password: password, data: walletJson);

      expect(File(path()).readAsBytesSync().first, cwb.lowEntropyVersion);
      expect(await encryption.read(path: path(), password: password), walletJson);
    });

    test('WalletKeysData JSON survives a write/read used by getSeeds', () async {
      final password = generateKey();
      final keys = WalletKeysData(
        mnemonic: 'abandon ability able about above absent absorb abstract',
        privateKey: 'deadbeef',
      );
      final encryption = encryptionFileUtilsFor(false);
      await encryption.write(path: path(), password: password, data: keys.toJSON());

      final decoded = json.decode(await encryption.read(path: path(), password: password))
          as Map<String, dynamic>;
      final restored = WalletKeysData.fromJSON(decoded);
      expect(restored.mnemonic, keys.mnemonic);
      expect(restored.privateKey, keys.privateKey);
    });
  });

  group('legacy Salsa20 migration', () {
    test('reads a Salsa20 wallet file and re-encrypts it as XChaCha20', () async {
      final password = generateKey();
      File(path()).writeAsStringSync(_salsa20Encrypt(password, walletJson));
      expect(File(path()).readAsBytesSync().first, isNot(cwb.lowEntropyVersion));
      expect(File(path()).readAsBytesSync().first, isNot(cwb.highEntropyVersion));

      final result = await encrypted_file.read(
        path: path(),
        password: password,
        highEntropyPassphrase: true,
      );

      expect(result, walletJson);
      expect(File(path()).readAsBytesSync().first, cwb.highEntropyVersion);
      expect(await encrypted_file.read(path: path(), password: password), walletJson);
    });

    test('migrated file can be opened with EncryptionFileUtils', () async {
      final password = generateKey();
      File(path()).writeAsStringSync(_salsa20Encrypt(password, walletJson));

      final encryption = encryptionFileUtilsFor(false);
      expect(await encryption.read(path: path(), password: password), walletJson);
      expect(await encryption.read(path: path(), password: password), walletJson);
    });

    test('wrong password does not rewrite the Salsa20 file', () async {
      final password = generateKey();
      final salsa = _salsa20Encrypt(password, walletJson);
      File(path()).writeAsStringSync(salsa);

      await expectLater(
        encrypted_file.read(path: path(), password: generateKey()),
        throwsLegacyDecryptError,
      );
      expect(File(path()).readAsStringSync(), salsa);
    });

    test('short or malformed password does not leak _readLegacy errors', () async {
      final password = generateKey();
      final salsa = _salsa20Encrypt(password, walletJson);
      File(path()).writeAsStringSync(salsa);

      await expectLater(
        encrypted_file.read(path: path(), password: 'user-pass'),
        throwsLegacyDecryptError,
      );
      expect(File(path()).readAsStringSync(), salsa);
    });

    test('corrupt non-base64 file does not leak _readLegacy errors', () async {
      File(path()).writeAsStringSync('not-valid-base64!!!');

      await expectLater(
        encrypted_file.read(path: path(), password: generateKey()),
        throwsLegacyDecryptError,
      );
      expect(File(path()).readAsStringSync(), 'not-valid-base64!!!');
    });

    test('invalid UTF-8 legacy bytes do not leak _readLegacy errors', () async {
      File(path()).writeAsBytesSync(const [0x00, 0xFF, 0xFE, 0x01]);

      await expectLater(
        encrypted_file.read(path: path(), password: generateKey()),
        throwsLegacyDecryptError,
      );
      expect(File(path()).readAsBytesSync(), const [0x00, 0xFF, 0xFE, 0x01]);
    });

    test('rejects Salsa20 plaintext that does not start with {"', () async {
      final password = generateKey();
      File(path()).writeAsStringSync(_salsa20Encrypt(password, 'not-json-payload'));

      await expectLater(
        encrypted_file.read(path: path(), password: password),
        throwsLegacyDecryptError,
      );
      expect(File(path()).readAsBytesSync().first, isNot(cwb.highEntropyVersion));
      expect(File(path()).readAsBytesSync().first, isNot(cwb.lowEntropyVersion));
    });

    test('does not re-encrypt Salsa20 data that starts with {" but is not JSON', () async {
      final password = generateKey();
      const garbage = '{"not valid json';
      File(path()).writeAsStringSync(_salsa20Encrypt(password, garbage));

      expect(await encrypted_file.read(path: path(), password: password), garbage);
      expect(File(path()).readAsBytesSync().first, isNot(cwb.highEntropyVersion));
      expect(File(path()).readAsBytesSync().first, isNot(cwb.lowEntropyVersion));
    });

    test(
      'wrong password that decrypts to {" does not rewrite the file',
      () async {
        final password = generateKey();
        final salsa = _salsa20Encrypt(password, walletJson);
        File(path()).writeAsStringSync(salsa);

        final collision = _findWrongPasswordWithJsonObjectPrefix(salsa);
        expect(collision, isNot(password));
        expect(_salsa20Decrypt(collision, salsa).startsWith('{"'), isTrue);
        expect(() => json.decode(_salsa20Decrypt(collision, salsa)), throwsA(anything));

        final result = await encrypted_file.read(path: path(), password: collision);

        expect(result.startsWith('{"'), isTrue);
        expect(result, isNot(walletJson));
        expect(File(path()).readAsStringSync(), salsa);
      },
    );
  });

  group('legacy Linux XChaCha20 Latin-1 payloads', () {
    test('decodes files stored as one byte per UTF-16 code unit', () async {
      final password = generateKey();
      const data = '{"name":"Café","mnemonic":"abandon"}';
      // Old XChaCha20EncryptionFileUtils used String.codeUnits instead of utf8.encode.
      final encrypted = await cwb.encrypt(
        password,
        Uint8List.fromList(data.codeUnits),
        highEntropyPassphrase: true,
      );
      File(path()).writeAsBytesSync(encrypted);

      expect(await encrypted_file.read(path: path(), password: password), data);
    });
  });

  group('generateKey', () {
    test('produces unique passwords that still encrypt and decrypt', () async {
      final a = generateKey();
      final b = generateKey();
      expect(a, isNot(b));
      expect(a.length, greaterThan(12));

      await encrypted_file.write(
        path: path(),
        password: a,
        data: walletJson,
        highEntropyPassphrase: true,
      );
      expect(await encrypted_file.read(path: path(), password: a), walletJson);
    });
  });
}

final throwsLegacyDecryptError = throwsA(
  isA<Exception>().having(
    (e) => e.toString(),
    'message',
    contains('Failed to decrypt legacy file'),
  ),
);

({encrypt.Key key, encrypt.IV iv}) _salsa20Keys(String password) {
  const ivEncodedStringLength = 12;
  return (
    key: encrypt.Key.fromBase64(password.substring(0, password.length - ivEncodedStringLength)),
    iv: encrypt.IV.fromBase64(password.substring(password.length - ivEncodedStringLength)),
  );
}

encrypt.Encrypter _salsa20(String password) {
  final keys = _salsa20Keys(password);
  return encrypt.Encrypter(encrypt.Salsa20(keys.key));
}

String _salsa20Encrypt(String password, String data) {
  final keys = _salsa20Keys(password);
  return _salsa20(password).encrypt(data, iv: keys.iv).base64;
}

String _salsa20Decrypt(String password, String data) {
  final keys = _salsa20Keys(password);
  return _salsa20(password).decrypt64(data, iv: keys.iv);
}

List<int> _salsa20DecryptBytes(String password, String data) {
  final keys = _salsa20Keys(password);
  return _salsa20(password).decryptBytes(encrypt.Encrypted.fromBase64(data), iv: keys.iv);
}

String _passwordFromNonce(int nonce) {
  final ivBytes = Uint8List(8);
  ivBytes.buffer.asByteData().setUint64(0, nonce, Endian.little);
  return encrypt.Key(Uint8List(32)).base64 + encrypt.IV(ivBytes).base64;
}

/// Salsa20 has no MAC, so a wrong key decrypts to garbage. The first two bytes
/// are `{"` about once in 2^16 tries; keep going until that happens, then skip
/// the much rarer case where the garbage is also valid JSON (that would rewrite).
String _findWrongPasswordWithJsonObjectPrefix(String ciphertext) {
  const maxAttempts = 1 << 20;
  for (var nonce = 0; nonce < maxAttempts; nonce++) {
    final candidate = _passwordFromNonce(nonce);
    final bytes = _salsa20DecryptBytes(candidate, ciphertext);
    if (bytes.length < 2 || bytes[0] != 0x7b || bytes[1] != 0x22) {
      continue;
    }
    try {
      json.decode(_salsa20Decrypt(candidate, ciphertext));
    } catch (_) {
      return candidate;
    }
  }
  fail('no Salsa20 {" prefix collision in $maxAttempts attempts');
}
