import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cw_monero/wallet_manager.dart' as monero_wallet_manager;
import 'package:cake_wallet/src/domain/common/wallet_info.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/wallets_manager.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';

Future<String> pathForWallet(
    {@required WalletType type, @required String name}) async {
  final directory = await getApplicationDocumentsDirectory();
  final pathDir = directory.path + '/wallets/${walletTypeToString(type).toLowerCase()}' + '/$name';
  final dir = Directory(pathDir);

  if (!await dir.exists()) {
    await dir.create();
  }

  return pathDir + '/$name';
}

class MoneroWalletsManager extends WalletsManager {
  MoneroWalletsManager({@required this.walletInfoSource});

  static const type = WalletType.monero;

  Box<WalletInfo> walletInfoSource;

  @override
  Future<Wallet> create(String name, String password, String language) async {
    try {
      const isRecovery = false;
      final path = await pathForWallet(type: WalletType.monero, name: name);

      await monero_wallet_manager.createWallet(
          path: path, password: password, language: language);

      final wallet = await MoneroWallet.createdWallet(
          walletInfoSource: walletInfoSource,
          name: name,
          isRecovery: isRecovery);
      await wallet.updateInfo();

      return wallet;
    } catch (e) {
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<Wallet> restoreFromSeed(
      String name, String password, String seed, int restoreHeight) async {
    try {
      const isRecovery = true;
      final path = await pathForWallet(type: WalletType.monero, name: name);

      await monero_wallet_manager.restoreFromSeed(
          path: path,
          password: password,
          seed: seed,
          restoreHeight: restoreHeight);

      final wallet = await MoneroWallet.createdWallet(
          walletInfoSource: walletInfoSource,
          name: name,
          isRecovery: isRecovery,
          restoreHeight: restoreHeight);
      await wallet.updateInfo();

      return wallet;
    } catch (e) {
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<Wallet> restoreFromKeys(
      String name,
      String password,
      String language,
      int restoreHeight,
      String address,
      String viewKey,
      String spendKey) async {
    try {
      const isRecovery = true;
      final path = await pathForWallet(type: WalletType.monero, name: name);

      await monero_wallet_manager.restoreFromKeys(
          path: path,
          password: password,
          language: language,
          restoreHeight: restoreHeight,
          address: address,
          viewKey: viewKey,
          spendKey: spendKey);

      final wallet = await MoneroWallet.createdWallet(
          walletInfoSource: walletInfoSource,
          name: name,
          isRecovery: isRecovery,
          restoreHeight: restoreHeight);
      await wallet.updateInfo();

      return wallet;
    } catch (e) {
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<Wallet> openWallet(String name, String password) async {
    try {
      final path = await pathForWallet(type: WalletType.monero, name: name);
      monero_wallet_manager.openWallet(path: path, password: password);
      final wallet = await MoneroWallet.load(walletInfoSource, name, type);
      await wallet.updateInfo();

      return wallet;
    } catch (e) {
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(type: WalletType.monero, name: name);
      return monero_wallet_manager.isWalletExist(path: path);
    } catch (e) {
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future remove(WalletDescription wallet) async {
    final dir = await getApplicationDocumentsDirectory();
    final root = dir.path.replaceAll('app_flutter', 'files');
    final walletFilePath = root + '/cw_monero/' + wallet.name;
    final keyPath = walletFilePath + '.keys';
    final addressFilePath = walletFilePath + '.address.txt';
    final walletFile = File(walletFilePath);
    final keyFile = File(keyPath);
    final addressFile = File(addressFilePath);

    if (await walletFile.exists()) {
      await walletFile.delete();
    }

    if (await keyFile.exists()) {
      await keyFile.delete();
    }

    if (await addressFile.exists()) {
      await addressFile.delete();
    }

    final id =
        walletTypeToString(wallet.type).toLowerCase() + '_' + wallet.name;
    final info = walletInfoSource.values
        .firstWhere((info) => info.id == id, orElse: () => null);

    await info?.delete();
  }
}
