import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_libmonero/entities/secret_store_key.dart';

class KeyService {
  KeyService(this._secureStorage);

  final dynamic _secureStorage;

  Future<String> getWalletPassword({String? walletName}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final password = await (_secureStorage.read(key: key) as FutureOr<String?>);

    return password!;
  }

  Future<void> saveWalletPassword(
      {String? walletName, required String password}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);

    await _secureStorage.write(key: key, value: password);
  }
}
