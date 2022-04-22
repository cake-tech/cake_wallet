import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_libmonero/entities/secret_store_key.dart';
import 'package:flutter_libmonero/entities/encrypt.dart';

class KeyService {
  KeyService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  Future<String> getWalletPassword({String walletName}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = await _secureStorage.read(key: key);

    return decodeWalletPassword(password: encodedPassword);
  }

  Future<void> saveWalletPassword({String walletName, String password}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = encodeWalletPassword(password: password);

    await _secureStorage.write(key: key, value: encodedPassword);
  }
}
