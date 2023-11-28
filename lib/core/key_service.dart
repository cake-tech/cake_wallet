import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/entities/encrypt.dart';

class KeyService {
  KeyService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  Future<String> getWalletPassword({required String walletName}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = await _secureStorage.read(key: key);
    return decodeWalletPassword(password: encodedPassword!);
  }

  Future<void> saveWalletPassword({required String walletName, required String password}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = encodeWalletPassword(password: password);

    await _secureStorage.delete(key: key);
    await _secureStorage.write(key: key, value: encodedPassword);
  }

  Future<void> deleteWalletPassword({required String walletName}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);

    await _secureStorage.delete(key: key);
  }
}
