import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/entities/encrypt.dart';

class KeyService {
  KeyService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  Future<String> getWalletPasswordV2({required String walletName}) async {
    final key =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = await _secureStorage.read(key: key);
    return decodeWalletPasswordV2(password: encodedPassword!);
  }

  Future<void> saveWalletPasswordV2({required String walletName, required String password}) async {
    final key =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = await encodeWalletPasswordV2(password: password);

    await _secureStorage.delete(key: key);
    await _secureStorage.write(key: key, value: encodedPassword);
  }

  Future<String> getWalletPasswordV1({required String walletName}) async {
    final key =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = await _secureStorage.read(key: key);
    return decodeWalletPasswordV1(password: encodedPassword!);
  }

  Future<void> saveWalletPasswordV1({required String walletName, required String password}) async {
    final key =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = encodeWalletPasswordV1(password: password);

    await _secureStorage.delete(key: key);
    await _secureStorage.write(key: key, value: encodedPassword);
  }

  Future<void> deleteWalletPassword({required String walletName}) async {
    final key =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);

    await _secureStorage.delete(key: key);
  }
}
