import 'package:encrypt/encrypt.dart';
// import 'package:password/password.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:dargon2_flutter/dargon2_flutter.dart';

Future<String> argon2Hash({required String password}) async {
  final result = await argon2.hashPasswordString(password, salt: Salt.newSalt());
  // the salt is stored within the encoded string:
  return result.encodedString;
}

Future<bool> verifyArgon2Hash({required String password, required String hash}) async {
  return argon2.verifyHashString(password, hash);
}

// @@@@@@@@@@@@@@@ OLD (kept for reference purposes, do not use!) @@@@@@@@@@@@@

String encrypt({required String source, required String key}) {
  final _key = Key.fromUtf8(key);
  final iv = IV.allZerosOfLength(16);
  final encrypter = Encrypter(AES(_key));
  final encrypted = encrypter.encrypt(source, iv: iv);
  return encrypted.base64;
}

String decrypt({required String source, required String key}) {
  final _key = Key.fromUtf8(key);
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

String encodedPinCode({required String pin}) {
  final source = '${secrets.salt}$pin';
  return encrypt(source: source, key: secrets.key);
}

String decodedPinCode({required String pin}) {
  final decrypted = decrypt(source: pin, key: secrets.key);
  return decrypted.substring(secrets.key.length, decrypted.length);
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
