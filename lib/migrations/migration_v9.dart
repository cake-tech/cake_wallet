import 'package:cake_wallet/di.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cake_wallet/entities/secret_store_key.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MigrationV9 {
  static Future<void> run() async {
    final secureStorage = getIt.get<FlutterSecureStorage>();
    await generateBackupPassword(secureStorage);
  }

  static Future<void> generateBackupPassword(
      FlutterSecureStorage secureStorage) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);

    if ((await secureStorage.read(key: key))?.isNotEmpty ?? false) {
      return;
    }

    final password = encrypt.Key.fromSecureRandom(32).base16;
    await secureStorage.write(key: key, value: password);
  }
}
