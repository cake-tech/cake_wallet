// import 'package:flutter_libmonero/di.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter_libmonero/core/generate_wallet_password.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';

class WalletCreationService {
  WalletService walletService;
  WalletCreationService(
      {this.secureStorage,
      this.keyService,
      this.sharedPreferences,
      this.walletService}) {
    if (type != null) {
      changeWalletType();
    }
  }

  WalletType type = WalletType.monero;
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;
  final KeyService keyService;
  WalletService _service;

  void changeWalletType() {
    this.type = WalletType.monero;
    _service = walletService;
  }

  Future<WalletBase> create(WalletCredentials credentials) async {
    final password = generateWalletPassword(type);
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    return await _service.create(credentials);
  }

  Future<WalletBase> restoreFromKeys(WalletCredentials credentials) async {
    final password = generateWalletPassword(type);
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    return await _service.restoreFromKeys(credentials);
  }

  Future<WalletBase> restoreFromSeed(WalletCredentials credentials) async {
    final password = generateWalletPassword(type);
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    return await _service.restoreFromSeed(credentials);
  }
}
