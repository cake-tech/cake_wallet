import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_service.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/secret_store_key.dart';
import 'package:cake_wallet/src/domain/common/encrypt.dart';

class WalletCreationService {
  WalletCreationService(
      {WalletType initialType,
      this.appStore,
      this.secureStorage,
      this.sharedPreferences})
      : type = initialType {
    if (type != null) {
      changeWalletType(type: type);
    }
  }

  WalletType type;
  final AppStore appStore;
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

//  final WalletService walletService;
//  final Box<WalletInfo> walletInfoSource;

  WalletService _service;

  void changeWalletType({@required WalletType type}) {
    this.type = type;

    switch (type) {
      case WalletType.monero:
        _service = MoneroWalletService();
        break;
      case WalletType.bitcoin:
        _service = BitcoinWalletService();
        break;
      default:
        break;
    }
  }

  Future<void> create(WalletCredentials credentials) async {
    final password = generateWalletPassword(type);
    credentials.password = password;
    await saveWalletPassword(password: password, walletName: credentials.name);
    final wallet = await _service.create(credentials);
    appStore.wallet = wallet;
    appStore.authenticationStore.allowed();
  }

  Future<void> restoreFromKeys(WalletCredentials credentials) async {
    final password = generateWalletPassword(type);
    credentials.password = password;
    await saveWalletPassword(password: password, walletName: credentials.name);
    final wallet = await _service.restoreFromKeys(credentials);
    appStore.wallet = wallet;
    appStore.authenticationStore.allowed();
  }

  Future<void> restoreFromSeed(WalletCredentials credentials) async {
    final password = generateWalletPassword(type);
    credentials.password = password;
    await saveWalletPassword(password: password, walletName: credentials.name);
    final wallet = await _service.restoreFromSeed(credentials);
    appStore.wallet = wallet;
    appStore.authenticationStore.allowed();
  }

  Future<String> getWalletPassword({String walletName}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = await secureStorage.read(key: key);

    return decodeWalletPassword(password: encodedPassword);
  }

  Future<void> saveWalletPassword({String walletName, String password}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = encodeWalletPassword(password: password);

    await secureStorage.write(key: key, value: encodedPassword);
  }
}
