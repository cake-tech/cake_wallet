import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

Future<List<int>> getEncryptionKey(
    {String forKey, FlutterSecureStorage secureStorage}) async {
  final stringifiedKey =
      await secureStorage.read(key: 'transactionDescriptionsBoxKey');
  List<int> key;

  if (stringifiedKey == null) {
    key = Hive.generateSecureKey();
    final keyStringified = key.join(',');
    await secureStorage.write(
        key: 'transactionDescriptionsBoxKey', value: keyStringified);
  } else {
    key = stringifiedKey
        .split(',')
        .map((i) => int.parse(i))
        .toList();
  }

  return key;
}