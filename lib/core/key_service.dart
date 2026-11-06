import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/wallet_info.dart";

class KeyService {
  KeyService(this._secureStorage);

  final SecureStorage _secureStorage;

  /// UUID wallets store their password under the id, legacy wallets under the name.
  static String passwordKeyOf(WalletInfo walletInfo) =>
      isUuidWallet(walletInfo) ? walletInfo.id : walletInfo.name;

  Future<String> getWalletPasswordForWallet(WalletInfo walletInfo) async {
    final encoded = await _secureStorage.read(key: _keyFor(passwordKeyOf(walletInfo)));
    if (encoded == null) throw const WalletOpenException("Wallet password not found");
    return decodeWalletPassword(password: encoded);
  }

  Future<void> saveWalletPasswordForWallet(WalletInfo walletInfo, String password) =>
      saveWalletPassword(walletName: passwordKeyOf(walletInfo), password: password);

  Future<void> deleteWalletPasswordForWallet(WalletInfo walletInfo) =>
      _secureStorage.delete(key: _keyFor(passwordKeyOf(walletInfo)));

  String _keyFor(String walletName) =>
      generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: walletName);

  Future<String> getWalletPassword({required String walletName}) async {
    final encodedPassword = await _secureStorage.read(key: _keyFor(walletName));
    return decodeWalletPassword(password: encodedPassword!);
  }

  Future<void> saveWalletPassword({required String walletName, required String password}) async {
    final encodedPassword = encodeWalletPassword(password: password);
    await _secureStorage.write(key: _keyFor(walletName), value: encodedPassword);
  }
}