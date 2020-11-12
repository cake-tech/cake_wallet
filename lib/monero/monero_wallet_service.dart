import 'dart:io';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:hive/hive.dart';
import 'package:cw_monero/wallet_manager.dart' as monero_wallet_manager;
import 'package:cw_monero/wallet.dart' as monero_wallet;
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/entities/pathForWallet.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

class MoneroNewWalletCredentials extends WalletCredentials {
  MoneroNewWalletCredentials({String name, String password, this.language})
      : super(name: name, password: password);

  final String language;
}

class MoneroRestoreWalletFromSeedCredentials extends WalletCredentials {
  MoneroRestoreWalletFromSeedCredentials(
      {String name, String password, int height, this.mnemonic})
      : super(name: name, password: password, height: height);

  final String mnemonic;
}

class MoneroWalletLoadingException implements Exception {
  @override
  String toString() => 'The wallet is damaged.';
}

class MoneroRestoreWalletFromKeysCredentials extends WalletCredentials {
  MoneroRestoreWalletFromKeysCredentials(
      {String name,
      String password,
      this.language,
      this.address,
      this.viewKey,
      this.spendKey,
      int height})
      : super(name: name, password: password, height: height);

  final String language;
  final String address;
  final String viewKey;
  final String spendKey;
}

class MoneroWalletService extends WalletService<
    MoneroNewWalletCredentials,
    MoneroRestoreWalletFromSeedCredentials,
    MoneroRestoreWalletFromKeysCredentials> {
  MoneroWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  @override
  Future<MoneroWallet> create(MoneroNewWalletCredentials credentials) async {
    try {
      final path =
          await pathForWallet(name: credentials.name, type: WalletType.monero);
      await monero_wallet_manager.createWallet(
          path: path,
          password: credentials.password,
          language: credentials.language);
      final wallet = MoneroWallet(
          filename: monero_wallet.getFilename(),
          walletInfo: credentials.walletInfo);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: ${e.toString()}');
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
      await monero_wallet_manager
          .openWalletAsync({'path': path, 'password': password});
      final walletInfo = walletInfoSource.values.firstWhere(
          (info) => info.id == WalletBase.idFor(name, WalletType.monero),
          orElse: () => null);
      final wallet = MoneroWallet(
          filename: monero_wallet.getFilename(), walletInfo: walletInfo);
      final isValid = await wallet.validate();

      if (!isValid) {
        // if (wallet.seed?.isNotEmpty ?? false) {
          // let restore from seed in this case;
          // final seed = wallet.seed;
          // final credentials = MoneroRestoreWalletFromSeedCredentials(
          //     name: name, password: password, mnemonic: seed, height: 2000000)
          //   ..walletInfo = walletInfo;
          // await remove(name);
          // return restoreFromSeed(credentials);
        // }

        throw MoneroWalletLoadingException();
      }

      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: WalletType.monero);
    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }
  }

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
      final wallet = MoneroWallet(
          filename: monero_wallet.getFilename(),
          walletInfo: credentials.walletInfo);
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
      final wallet = MoneroWallet(
          filename: monero_wallet.getFilename(),
          walletInfo: credentials.walletInfo);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }
}
