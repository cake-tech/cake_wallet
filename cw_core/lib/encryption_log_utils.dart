import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:mutex/mutex.dart';
import 'package:cw_core/.secrets.g.dart' as secrets;

final logMutex = Mutex();
final password = secrets.logPassword.isEmpty ? ':)' : secrets.logPassword;
final salt = secrets.logSalt.isEmpty ? '(:' : secrets.logSalt;

class EncryptionLogUtil {
  static final _algorithm = AesGcm.with256bits();
  static SecretKey? cachedKey = null;
  static Future<SecretKey> _deriveKey() async {
    if (cachedKey != null) {
      return cachedKey!;
    }
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 120000, // OWASP recommendation: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#pbkdf2
      bits: 256,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: utf8.encode(salt),
    );
    cachedKey = key;
    return key;
  }

  static Future<void> write({required String path, required String data}) async {
    await logMutex.acquire();
    try {
      final key = await _deriveKey();
      final secretKey = await _algorithm.newSecretKey();
      final iv = await secretKey.extractBytes();
      
      final nonce = iv.sublist(0, 12);

      final secretBox = await _algorithm.encrypt(
        utf8.encode(data),
        secretKey: key,
        nonce: nonce,
      );

      final line = base64.encode([...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes]);
      File(path).writeAsStringSync("$line\n", mode: FileMode.append);
    } finally {
      logMutex.release();
    }
  }

  static Future<String> read({required String path}) async {
    await logMutex.acquire();
    try {
      final key = await _deriveKey();
      final file = File(path);
      final lines = file.readAsLinesSync();
      final sb = StringBuffer();

      for (final line in lines) {
        try {
          final bytes = base64.decode(line);
          final nonce = bytes.sublist(0, 12);
          final cipherText = bytes.sublist(12, bytes.length - 16);
          final macBytes = bytes.sublist(bytes.length - 16);

          final secretBox = SecretBox(
            cipherText,
            nonce: nonce,
            mac: Mac(macBytes),
          );

          final decrypted = await _algorithm.decrypt(secretBox, secretKey: key);
          sb.write(utf8.decode(decrypted));
        } catch (_) {
          sb.writeln(line);
        }
      }

      return sb.toString();
    } finally {
      logMutex.release();
    }
  }
}
