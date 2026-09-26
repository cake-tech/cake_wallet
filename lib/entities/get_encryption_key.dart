import 'dart:io';

import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/hive_key_file.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/root_dir.dart';

const legacyTransactionDescriptionsBoxKey = 'transactionDescriptionsBoxKey';

Future<List<int>> getEncryptionKey(
    {required String forKey, required SecureStorage secureStorage}) async {
  String? stringifiedKey = await _readStoredKey(secureStorage, forKey);

  if (stringifiedKey == null && forKey != legacyTransactionDescriptionsBoxKey) {
    stringifiedKey = await _readStoredKey(secureStorage, legacyTransactionDescriptionsBoxKey);
  }

  if (stringifiedKey == null && Platform.isLinux) {
    final appDir = await getAppDir();
    stringifiedKey = await readHiveKeyFile(appDir, forKey);
    if (stringifiedKey == null && forKey != legacyTransactionDescriptionsBoxKey) {
      stringifiedKey = await readHiveKeyFile(appDir, legacyTransactionDescriptionsBoxKey);
    }
  }

  final List<int> key;
  if (stringifiedKey == null) {
    key = CakeHive.generateSecureKey();
    stringifiedKey = key.join(',');
  } else {
    key = stringifiedKey.split(',').map((i) => int.parse(i)).toList();
  }

  try {
    await secureStorage.write(key: forKey, value: stringifiedKey);
  } catch (_) {
    if (!Platform.isLinux) {
      rethrow;
    }
  }

  if (Platform.isLinux) {
    await writeHiveKeyFile(await getAppDir(), forKey, stringifiedKey);
  }

  return key;
}

Future<String?> _readStoredKey(SecureStorage secureStorage, String key) async {
  try {
    return await secureStorage.read(key: key);
  } catch (_) {
    return null;
  }
}
