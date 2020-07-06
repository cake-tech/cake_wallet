import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_service.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

class WalletCreationService {
  WalletCreationService(
      {WalletType initialType,
      this.appStore,
      this.secureStorage,
      this.keyService,
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
  final KeyService keyService;
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
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    final wallet = await _service.create(credentials);
    appStore.wallet = wallet;
    appStore.authenticationStore.allowed();
  }

  Future<void> restoreFromKeys(WalletCredentials credentials) async {
    final password = generateWalletPassword(type);
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    final wallet = await _service.restoreFromKeys(credentials);
    appStore.wallet = wallet;
    appStore.authenticationStore.allowed();
  }

  Future<void> restoreFromSeed(WalletCredentials credentials) async {
    final password = generateWalletPassword(type);
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    final wallet = await _service.restoreFromSeed(credentials);
    appStore.wallet = wallet;
    appStore.authenticationStore.allowed();
  }
}
