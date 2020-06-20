import 'dart:async';
import 'package:cake_wallet/bitcoin/key.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/src/domain/common/encrypt.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';
import 'package:cake_wallet/src/domain/common/wallets_manager.dart';
import 'package:cake_wallet/src/domain/common/secret_store_key.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/monero/monero_wallets_manager.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';

class WalletIsExistException implements Exception {
  WalletIsExistException(this.name);

  String name;

  @override
  String toString() => "Wallet with name $name is already exist!";
}

class WalletListService {
  WalletListService(
      {this.secureStorage,
      this.walletInfoSource,
      this.walletsManager,
      @required this.walletService,
      @required this.sharedPreferences})
      : _type = WalletType.monero;

  final FlutterSecureStorage secureStorage;
  final WalletService walletService;
  final Box<WalletInfo> walletInfoSource;
  final SharedPreferences sharedPreferences;
  WalletsManager walletsManager;
  WalletType _type;

  Future<List<WalletDescription>> getAll() async => walletInfoSource.values
      .map((info) => WalletDescription(name: info.name, type: info.type))
      .toList();

  Future create(String name, String language) async {
    if (await walletsManager.isWalletExit(name)) {
      throw WalletIsExistException(name);
    }

    if (walletService.currentWallet != null) {
      await walletService.close();
    }

    final password = _generatePassword();
    await saveWalletPassword(password: password, walletName: name);

    final wallet = await walletsManager.create(name, password, language);

    await onWalletChange(wallet);
  }

  Future restoreFromSeed(String name, String seed, int restoreHeight) async {
    if (await walletsManager.isWalletExit(name)) {
      throw WalletIsExistException(name);
    }

    if (walletService.currentWallet != null) {
      await walletService.close();
    }

    final password = _generatePassword();
    await saveWalletPassword(password: password, walletName: name);

    final wallet = await walletsManager.restoreFromSeed(
        name, password, seed, restoreHeight);

    await onWalletChange(wallet);
  }

  Future restoreFromKeys(String name, String language, int restoreHeight,
      String address, String viewKey, String spendKey) async {
    if (await walletsManager.isWalletExit(name)) {
      throw WalletIsExistException(name);
    }

    if (walletService.currentWallet != null) {
      await walletService.close();
    }

    final password = _generatePassword();
    await saveWalletPassword(password: password, walletName: name);

    final wallet = await walletsManager.restoreFromKeys(
        name, password, language, restoreHeight, address, viewKey, spendKey);

    await onWalletChange(wallet);
  }

  Future openWallet(String name) async {
    if (walletService.currentWallet != null) {
      await walletService.close();
    }

    final password = await getWalletPassword(walletName: name);
    final wallet = await walletsManager.openWallet(name, password);

    await onWalletChange(wallet);
  }

  Future changeWalletManger({WalletType walletType}) async {
    _type = walletType;

    switch (walletType) {
      case WalletType.monero:
        walletsManager =
            MoneroWalletsManager(walletInfoSource: walletInfoSource);
        break;
      case WalletType.bitcoin:
//        walletsManager = BitcoinWalletManager();
        break;
      case WalletType.none:
        walletsManager = null;
        break;
    }
  }

  Future onWalletChange(Wallet wallet) async {
    walletService.currentWallet = wallet;
    final walletName = await wallet.getName();
    print('walletName $walletName ');
    await sharedPreferences.setString('current_wallet_name', walletName);
  }

  Future remove(WalletDescription wallet) async =>
      await walletsManager.remove(wallet);

  Future<String> getWalletPassword({String walletName}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = await secureStorage.read(key: key);

    return decodeWalletPassword(password: encodedPassword);
  }

  Future saveWalletPassword({String walletName, String password}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final encodedPassword = encodeWalletPassword(password: password);

    await secureStorage.write(key: key, value: encodedPassword);
  }

  String _generatePassword() {
    switch (_type) {
      case WalletType.bitcoin:
        return generateKey();
      default:
        return Uuid().v4();
    }
  }
}
