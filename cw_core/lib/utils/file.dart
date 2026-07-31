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
    await _writeXChaCha20(
      path: path,
      password: password,
      data: data,
      highEntropyPassphrase: useHighEntropy,
    );
    return data;
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
    Uint8List.fromList(data.codeUnits),
    highEntropyPassphrase: highEntropyPassphrase,
  );
  await File(path).writeAsBytes(encrypted);
}

Future<String> _readXChaCha20({
  required String path,
  required String password,
}) async {
  final encrypted = await File(path).readAsBytes();
  final bytes = await cwb.decrypt(password, encrypted);
  return String.fromCharCodes(bytes);
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
