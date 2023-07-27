import 'package:encrypt/encrypt.dart' as encrypt;

const ivEncodedStringLength = 12;

String generateKey() {
  final key = encrypt.Key.fromSecureRandom(512);
  final iv = encrypt.IV.fromSecureRandom(8);

  return key.base64 + iv.base64;
}

List<String> extractKeys(String key) {
  final _key = key.substring(0, key.length - ivEncodedStringLength);
  final iv = key.substring(key.length - ivEncodedStringLength);

  return [_key, iv];
}

Future<String> encode({required encrypt.Key key, required encrypt.IV iv, required String data}) async {
  final encrypter = encrypt.Encrypter(encrypt.Salsa20(key));
  final encrypted = encrypter.encrypt(data, iv: iv);

  return encrypted.base64;
}

Future<String> decode({required String password, required String data}) async {
  final keys = extractKeys(password);
  final key = encrypt.Key.fromBase64(keys.first);
  final iv = encrypt.IV.fromBase64(keys.last);
  final encrypter = encrypt.Encrypter(encrypt.Salsa20(key));
  final encrypted = encrypter.decrypt64(data, iv: iv);

  return encrypted;
}
