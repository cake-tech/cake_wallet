import 'package:cake_wallet/di.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';

class WalletCreationService {
  WalletCreationService(
      {WalletType initialType,
      this.secureStorage,
      this.keyService,
      this.sharedPreferences,
      this.walletInfoSource})
      : type = initialType {
    if (type != null) {
      changeWalletType(type: type);
    }
  }

  WalletType type;
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;
  final KeyService keyService;
  final Box<WalletInfo> walletInfoSource;
  WalletService _service;

  static const _isNewMoneroWalletPasswordUpdated = true;

  void changeWalletType({@required WalletType type}) {
    this.type = type;
    _service = getIt.get<WalletService>(param1: type);
  }

  bool exists(String name) {
    final walletName = name.toLowerCase();
    return walletInfoSource
      .values
      .any((walletInfo) => walletInfo.name.toLowerCase() == walletName);
  }

  void checkIfExists(String name) {
    if (exists(name)) {
      throw Exception('Wallet with name ${name} already exists!');
    }
  }

  Future<WalletBase> create(WalletCredentials credentials) async {
    checkIfExists(credentials.name);
    final password = generateWalletPassword();
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    final wallet =  await _service.create(credentials);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences
        .setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name),
          _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  Future<WalletBase> restoreFromKeys(WalletCredentials credentials) async {
    checkIfExists(credentials.name);
    final password = generateWalletPassword();
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    final wallet = await _service.restoreFromKeys(credentials);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences
        .setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name),
          _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  Future<WalletBase> restoreFromSeed(WalletCredentials credentials) async {
    checkIfExists(credentials.name);
    final password = generateWalletPassword();
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    final wallet = await _service.restoreFromSeed(credentials);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences
        .setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name),
          _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }
}
