import 'package:cake_wallet/entities/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encrypt helpers', () {
    test('round-trip works for keys with invalid AES lengths', () {
      const source = 'pin-payload';
      const encryptionKey = 'ci-fallback-key';

      final encrypted = encrypt(source: source, key: encryptionKey);

      expect(decrypt(source: encrypted, key: encryptionKey), source);
    });

    test('decodedPinCode strips the salt prefix, not the key length', () {
      const pin = '123456';
      const salt = 'salt-prefix';
      const encryptionKey = 'ci-fallback-key';

      final encoded = encodedPinCode(
        pin: pin,
        salt: salt,
        encryptionKey: encryptionKey,
      );

      expect(
        decodedPinCode(
          pin: encoded,
          salt: salt,
          encryptionKey: encryptionKey,
        ),
        pin,
      );
    });
  });
}
