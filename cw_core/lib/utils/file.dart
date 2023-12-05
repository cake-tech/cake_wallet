import 'dart:io';
import 'package:cw_core/key.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

Future<void> write({required String path, required String password, required String data}) async =>
    writeData(path: path, password: password, data: data);

Future<void> writeData(
    {required String path,
    required String password,
    required String data}) async {
  final keys = extractKeys(password);
  final key = encrypt.Key.fromBase64(keys.first);
  final iv = encrypt.IV.fromBase64(keys.last);
  final encrypted = await encode(key: key, iv: iv, data: data);
  final f = File(path);
  f.writeAsStringSync(encrypted);
}

Future<String> read({required String path, required String password}) async {
  final file = File(path);

  if (!file.existsSync()) {
    file.createSync();
  }

  final encrypted = file.readAsStringSync();

  return decode(password: password, data: encrypted);
}
