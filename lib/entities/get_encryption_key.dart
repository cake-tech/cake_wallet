import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cw_core/cake_hive.dart';

Future<List<int>> getEncryptionKey(
    {required String forKey, required SecureStorage secureStorage}) async {
  final stringifiedKey = await secureStorage.read(key: 'transactionDescriptionsBoxKey');
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