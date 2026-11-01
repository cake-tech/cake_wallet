import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";

class WalletPasswordNotFoundException implements Exception {
  WalletPasswordNotFoundException(this.walletId);

  final String walletId;

  @override
  String toString() => "No stored password found for wallet id $walletId";
}

class KeyService {
  KeyService(this._secureStorage);

  final SecureStorage _secureStorage;

  Future<String> getWalletPassword({required String walletName}) async {
    final key =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = await _secureStorage.read(key: key);
    return decodeWalletPassword(password: encodedPassword!);
  }

  Future<void> saveWalletPassword({required String walletName, required String password}) async {
    final key =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = encodeWalletPassword(password: password);

    await _secureStorage.write(key: key, value: encodedPassword);
  }

  Future<void> deleteWalletPassword({required String walletName}) async {
    final key =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);

    await _secureStorage.delete(key: key);
  }

  Future<String?> _readWalletPasswordForId(String walletId) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletId: walletId);
    final encodedPassword = await _secureStorage.read(key: key);
    if (encodedPassword == null) return null;
    return decodeWalletPassword(password: encodedPassword);
  }

  Future<String> getWalletPasswordForId({required String walletId}) async {
    final password = await _readWalletPasswordForId(walletId);
    if (password == null) throw WalletPasswordNotFoundException(walletId);
    return password;
  }

  Future<void> saveWalletPasswordForId({required String walletId, required String password}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletId: walletId);
    final encodedPassword = encodeWalletPassword(password: password);
    await _secureStorage.write(key: key, value: encodedPassword);
  }

  Future<void> deleteWalletPasswordForId({required String walletId}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletId: walletId);
    await _secureStorage.delete(key: key);
  }

  Future<String> getWalletPasswordForWallet(WalletInfo walletInfo) async {
    final idPassword = await _readWalletPasswordForId(walletInfo.id);
    if (idPassword != null) {
      return idPassword;
    }

    final legacyKey = generateStoreKeyFor(
      key: SecretStoreKey.moneroWalletPassword,
      walletName: walletInfo.name,
    );
    final legacyEncoded = await _secureStorage.read(key: legacyKey);
    if (legacyEncoded == null) {
      throw WalletPasswordNotFoundException(walletInfo.id);
    }
    final legacyPassword = decodeWalletPassword(password: legacyEncoded);

    await saveWalletPasswordForId(walletId: walletInfo.id, password: legacyPassword);
    final verify = await _readWalletPasswordForId(walletInfo.id);
    if (verify == legacyPassword) {
      await _secureStorage.delete(key: legacyKey);
      printV(
          "migrated password for wallet ${walletInfo.id} (${walletInfo.name}) from legacy name-keyed storage");
    } else {
      printV(
          "WARNING migrating password for wallet ${walletInfo.id} (${walletInfo.name}) — id-keyed write did not verify, keeping legacy entry");
    }

    return legacyPassword;
  }

  Future<void> saveWalletPasswordForWallet({
    required WalletInfo walletInfo,
    required String password,
  }) =>
      saveWalletPasswordForId(walletId: walletInfo.id, password: password);

  Future<void> deleteWalletPasswordForWallet(WalletInfo walletInfo) =>
      deleteWalletPasswordForId(walletId: walletInfo.id);
}
