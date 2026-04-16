import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart';
// import 'package:password/password.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

Key _buildEncryptionKey(String secret) {
  final keyBytes = utf8.encode(secret);

  if (keyBytes.length == 16 || keyBytes.length == 24 || keyBytes.length == 32) {
    return Key(Uint8List.fromList(keyBytes));
  }

  return Key(Uint8List.fromList(crypto.sha256.convert(keyBytes).bytes));
}

String encrypt({required String source, required String key}) {
  final _key = _buildEncryptionKey(key);
  final iv = IV.allZerosOfLength(16);
  final encrypter = Encrypter(AES(_key));
  final encrypted = encrypter.encrypt(source, iv: iv);

  return encrypted.base64;
}

String decrypt({required String source, required String key}) {
  final _key = _buildEncryptionKey(key);
  final iv = IV.allZerosOfLength(16);
  final encrypter = Encrypter(AES(_key));
  final decrypted = encrypter.decrypt64(source, iv: iv);

  return decrypted;
}

String hash({required String source}) {
  // FIX-ME: Uninplemented
  throw Exception('Unimplemented');
  // final algorithm = PBKDF2();
  // final hash = Password.hash(source, algorithm);

  // return hash;
}

String encodedPinCode({
  required String pin,
  String? salt,
  String? encryptionKey,
}) {
  final saltPrefix = salt ?? secrets.salt;
  final source = '$saltPrefix$pin';

  return encrypt(source: source, key: encryptionKey ?? secrets.key);
}

String decodedPinCode({
  required String pin,
  String? salt,
  String? encryptionKey,
}) {
  final saltPrefix = salt ?? secrets.salt;
  final decrypted = decrypt(source: pin, key: encryptionKey ?? secrets.key);

  return decrypted.startsWith(saltPrefix)
      ? decrypted.substring(saltPrefix.length, decrypted.length)
      : decrypted;
}

String encodeWalletPassword({required String password}) {
  final source = password;
  final _key = secrets.shortKey + secrets.walletSalt;

  return encrypt(source: source, key: _key);
}

String decodeWalletPassword({required String password}) {
  final source = password;
  final _key = secrets.shortKey + secrets.walletSalt;

  return decrypt(source: source, key: _key);
}
