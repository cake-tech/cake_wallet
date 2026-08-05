import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cake_backup/backup.dart' as cwb;
import 'package:encrypt/encrypt.dart' as encrypt;

const _ivEncodedStringLength = 12;

Future<void> write({
  required String path,
  required String password,
  required String data,
  bool? highEntropyPassphrase,
}) async {
  await _writeXChaCha20(
    path: path,
    password: password,
    data: data,
    highEntropyPassphrase: highEntropyPassphrase ?? !Platform.isLinux,
  );
}

Future<String> read({
  required String path,
  required String password,
  bool? highEntropyPassphrase,
}) async {
  final useHighEntropy = highEntropyPassphrase ?? !Platform.isLinux;
  try {
    return await _readXChaCha20(path: path, password: password);
  } catch (e) {
    final encrypted = await File(path).readAsBytes();
    if (encrypted.isNotEmpty &&
        (encrypted[0] == cwb.lowEntropyVersion || encrypted[0] == cwb.highEntropyVersion)) {
      rethrow;
    }

    final data = await _readLegacy(path: path, password: password);
    if (data.isEmpty) {
      throw Exception('Failed to read data');
    }

    // Salsa20 is unauthenticated, so a wrong password decrypts to garbage instead of
    // failing. Every payload written here is a JSON object with at least one key, so a
    // correctly decrypted file always starts with '{"' and anything else is a bad
    // password.
    // There's 1 in 2^16 chance that this will be a false positive, but check later
    // prevents any damage to the file caused by re-encryption.
    if (!data.startsWith('{"')) {
      throw Exception('Failed to decrypt legacy file: invalid password or corrupted data');
    }

    if (_isJson(data)) {
      await _writeXChaCha20(
        path: path,
        password: password,
        data: data,
        highEntropyPassphrase: useHighEntropy,
      );
    }

    return data;
  }
}

bool _isJson(String data) {
  try {
    json.decode(data);
    return true;
  } catch (_) {
    return false;
  }
}

Future<String> _readLegacy({required String path, required String password}) async {
  final file = File(path);

  if (!file.existsSync()) {
    file.createSync();
  }

  final encrypted = file.readAsStringSync();

  return _decode(password: password, data: encrypted);
}

Future<void> _writeXChaCha20({
  required String path,
  required String password,
  required String data,
  required bool highEntropyPassphrase,
}) async {
  final encrypted = await cwb.encrypt(
    password,
    Uint8List.fromList(utf8.encode(data)),
    highEntropyPassphrase: highEntropyPassphrase,
  );

  final tmpFile = File('$path.tmp');
  await tmpFile.writeAsBytes(encrypted, flush: true);
  await tmpFile.rename(path);
}

Future<String> _readXChaCha20({
  required String path,
  required String password,
}) async {
  final encrypted = await File(path).readAsBytes();
  final bytes = await cwb.decrypt(password, encrypted);
  return _decodeUtf8(bytes);
}

// Linux wallets written by the old XChaCha20EncryptionFileUtils stored one byte per
// UTF-16 code unit, so bytes above 0x7F in those files are Latin-1 rather than UTF-8.
String _decodeUtf8(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return String.fromCharCodes(bytes);
  }
}

List<String> _extractKeys(String key) {
  final k = key.substring(0, key.length - _ivEncodedStringLength);
  final iv = key.substring(key.length - _ivEncodedStringLength);

  return [k, iv];
}

Future<String> _decode({required String password, required String data}) async {
  final keys = _extractKeys(password);
  final key = encrypt.Key.fromBase64(keys.first);
  final iv = encrypt.IV.fromBase64(keys.last);
  final encrypter = encrypt.Encrypter(encrypt.Salsa20(key));

  return encrypter.decrypt64(data, iv: iv);
}
