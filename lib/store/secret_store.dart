import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobx/mobx.dart';

part 'secret_store.g.dart';

class SecretStore = SecretStoreBase with _$SecretStore;

abstract class SecretStoreBase with Store {
  static Future<SecretStore> load(FlutterSecureStorage storage) async {
    final secretStore = SecretStore();
    final backupPasswordKey = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword = await storage.read(key: backupPasswordKey);
    // FIX-ME: backupPassword ?? '' ???
    secretStore.write(key: backupPasswordKey, value: backupPassword ?? '');

    return secretStore;
  }

  SecretStoreBase() : values = ObservableMap<String, String>();

  ObservableMap values;

  String read(String key) => values[key] as String;

  String write({required String key, required String value}) =>
      values[key] = value;
}
