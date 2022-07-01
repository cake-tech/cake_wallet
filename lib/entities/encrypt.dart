import 'package:encrypt/encrypt.dart';
import 'package:password/password.dart';
import 'package:flutter_libmonero/.secrets.g.dart' as secrets;

String encrypt({required String source, required String key, int keyLength = 16}) {
  final _key = Key.fromUtf8(key);
  final iv = IV.fromLength(keyLength);
  final encrypter = Encrypter(AES(_key));
  final encrypted = encrypter.encrypt(source, iv: iv);

  return encrypted.base64;
}

String decrypt({required String source, required String key, int keyLength = 16}) {
  final _key = Key.fromUtf8(key);
  final iv = IV.fromLength(keyLength);
  final encrypter = Encrypter(AES(_key));
  final decrypted = encrypter.decrypt64(source, iv: iv);

  return decrypted;
}

String hash({required String source}) {
  final algorithm = PBKDF2();
  final hash = Password.hash(source, algorithm);

  return hash;
}

String encodedPinCode({String? pin}) {
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
