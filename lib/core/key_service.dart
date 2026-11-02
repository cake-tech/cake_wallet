import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/wallet_info.dart";

class KeyService {
  KeyService(this._secureStorage);

  final SecureStorage _secureStorage;

  /// New wallets store their password under the wallet id; legacy wallets under the name.
  Future<String> getWalletPasswordForWallet(WalletInfo walletInfo) async {
    final byId = await _secureStorage.read(key: _keyFor(walletInfo.id));
    if (byId != null) return decodeWalletPassword(password: byId);

    // Only legacy wallets ever stored their password under the name.
    if (isUuidWallet(walletInfo)) throw WalletOpenException("Wallet password not found");

    final byName = await _secureStorage.read(key: _keyFor(walletInfo.name));
    if (byName == null) throw WalletOpenException("Wallet password not found");
    return decodeWalletPassword(password: byName);
  }

  Future<void> saveWalletPasswordForWallet(WalletInfo walletInfo, String password) =>
      saveWalletPassword(
          walletName: isUuidWallet(walletInfo) ? walletInfo.id : walletInfo.name,
          password: password);

  String _keyFor(String walletName) =>
      generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);


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
}
