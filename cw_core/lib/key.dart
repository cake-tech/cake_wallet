import 'package:encrypt/encrypt.dart' as encrypt;

String generateKey() {
  final key = encrypt.Key.fromSecureRandom(512);
  final iv = encrypt.IV.fromSecureRandom(8);

  return key.base64 + iv.base64;
}
