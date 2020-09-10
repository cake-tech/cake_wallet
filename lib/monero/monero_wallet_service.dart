import 'dart:io';

import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/src/domain/common/pathForWallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cw_monero/wallet_manager.dart' as monero_wallet_manager;
import 'package:cw_monero/wallet.dart' as monero_wallet;

class MoneroNewWalletCredentials extends WalletCredentials {
  MoneroNewWalletCredentials({String name, String password, this.language})
      : super(name: name, password: password);

  final String language;
}

class MoneroRestoreWalletFromSeedCredentials extends WalletCredentials {
  MoneroRestoreWalletFromSeedCredentials(
      {String name, String password, this.mnemonic, this.height})
      : super(name: name, password: password);

  final String mnemonic;
  final int height;
}

class MoneroRestoreWalletFromKeysCredentials extends WalletCredentials {
  MoneroRestoreWalletFromKeysCredentials(
      {String name,
      String password,
      this.language,
      this.address,
      this.viewKey,
      this.spendKey,
      this.height})
      : super(name: name, password: password);

  final String language;
  final String address;
  final String viewKey;
  final String spendKey;
  final int height;
}

class MoneroWalletService extends WalletService<
    MoneroNewWalletCredentials,
    MoneroRestoreWalletFromSeedCredentials,
    MoneroRestoreWalletFromKeysCredentials> {
  @override
  Future<MoneroWallet> create(MoneroNewWalletCredentials credentials) async {
    try {
      final path =
          await pathForWallet(name: credentials.name, type: WalletType.monero);

      await monero_wallet_manager.createWallet(
          path: path,
          password: credentials.password,
          language: credentials.language);

      final wallet = MoneroWallet(filename: monero_wallet.getFilename());
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name, type: WalletType.monero);
      return monero_wallet_manager.isWalletExist(path: path);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<MoneroWallet> openWallet(String name, String password) async {
    try {
      final path = await pathForWallet(name: name, type: WalletType.monero);
      monero_wallet_manager.openWallet(path: path, password: password);
      final wallet = MoneroWallet(filename: monero_wallet.getFilename());
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> remove(String wallet) async =>
      File(await pathForWalletDir(name: wallet, type: WalletType.bitcoin))
          .delete(recursive: true);

  @override
  Future<MoneroWallet> restoreFromKeys(
      MoneroRestoreWalletFromKeysCredentials credentials) async {
    try {
      final path =
          await pathForWallet(name: credentials.name, type: WalletType.monero);

      await monero_wallet_manager.restoreFromKeys(
          path: path,
          password: credentials.password,
          language: credentials.language,
          restoreHeight: credentials.height,
          address: credentials.address,
          viewKey: credentials.viewKey,
          spendKey: credentials.spendKey);

      final wallet = MoneroWallet(filename: monero_wallet.getFilename());
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<MoneroWallet> restoreFromSeed(
      MoneroRestoreWalletFromSeedCredentials credentials) async {
    try {
      final path =
          await pathForWallet(name: credentials.name, type: WalletType.monero);

      await monero_wallet_manager.restoreFromSeed(
          path: path,
          password: credentials.password,
          seed: credentials.mnemonic,
          restoreHeight: credentials.height);

      final wallet = MoneroWallet(filename: monero_wallet.getFilename());
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }
}
