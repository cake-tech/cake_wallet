import 'dart:io';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_monero/api/wallet_manager.dart' as monero_wallet_manager;
import 'package:cw_monero/monero_wallet.dart';
import 'package:hive/hive.dart';

class MoneroNewWalletCredentials extends WalletCredentials {
  MoneroNewWalletCredentials({required String name, required this.language, String? password})
      : super(name: name, password: password);

  final String language;
}

class MoneroRestoreWalletFromSeedCredentials extends WalletCredentials {
  MoneroRestoreWalletFromSeedCredentials(
      {required String name, required this.mnemonic, int height = 0, String? password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
}

class MoneroWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class MoneroRestoreWalletFromKeysCredentials extends WalletCredentials {
  MoneroRestoreWalletFromKeysCredentials(
      {required String name,
      required String password,
      required this.language,
      required this.address,
      required this.viewKey,
      required this.spendKey,
      int height = 0})
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
  MoneroWalletService(this.walletInfoSource, this.unspentCoinsInfoSource);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  
  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.monero;

  @override
  Future<MoneroWallet> create(MoneroNewWalletCredentials credentials) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await monero_wallet_manager.createWallet(
          path: path,
          password: credentials.password!,
          language: credentials.language);
      final wallet = MoneroWallet(
          walletInfo: credentials.walletInfo!, unspentCoinsInfo: unspentCoinsInfoSource);
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
      final path = await pathForWallet(name: name, type: getType());
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
      final path = await pathForWallet(name: name, type: getType());

      if (walletFilesExist(path)) {
        await repairOldAndroidWallet(name);
      }

      await monero_wallet_manager
          .openWalletAsync({'path': path, 'password': password});
      final walletInfo = walletInfoSource.values.firstWhere(
          (info) => info.id == WalletBase.idFor(name, getType()));
      final wallet = MoneroWallet(walletInfo: walletInfo, unspentCoinsInfo: unspentCoinsInfoSource);
      final isValid = wallet.walletAddresses.validate();

      if (!isValid) {
        await restoreOrResetWalletFiles(name);
        wallet.close();
        return openWallet(name, password);
      }

      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.

      if ((e.toString().contains('bad_alloc') ||
          (e is WalletOpeningException &&
              (e.message == 'std::bad_alloc' ||
                  e.message.contains('bad_alloc')))) ||
          (e.toString().contains('does not correspond') ||
          (e is WalletOpeningException &&
            e.message.contains('does not correspond')))) {
        await restoreOrResetWalletFiles(name);
        return openWallet(name, password);
      }

      rethrow;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }

    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(wallet, getType()));
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<void> rename(
      String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values.firstWhere(
        (info) => info.id == WalletBase.idFor(currentName, getType()));
    final currentWallet =
        MoneroWallet(walletInfo: currentWalletInfo, unspentCoinsInfo: unspentCoinsInfoSource);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<MoneroWallet> restoreFromKeys(
      MoneroRestoreWalletFromKeysCredentials credentials) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await monero_wallet_manager.restoreFromKeys(
          path: path,
          password: credentials.password!,
          language: credentials.language,
          restoreHeight: credentials.height!,
          address: credentials.address,
          viewKey: credentials.viewKey,
          spendKey: credentials.spendKey);
      final wallet = MoneroWallet(
          walletInfo: credentials.walletInfo!, unspentCoinsInfo: unspentCoinsInfoSource);
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
      final path = await pathForWallet(name: credentials.name, type: getType());
      await monero_wallet_manager.restoreFromSeed(
          path: path,
          password: credentials.password!,
          seed: credentials.mnemonic,
          restoreHeight: credentials.height!);
      final wallet = MoneroWallet(
          walletInfo: credentials.walletInfo!, unspentCoinsInfo: unspentCoinsInfoSource);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  Future<void> repairOldAndroidWallet(String name) async {
    try {
      if (!Platform.isAndroid) {
        return;
      }

      final oldAndroidWalletDirPath =
          await outdatedAndroidPathForWalletDir(name: name);
      final dir = Directory(oldAndroidWalletDirPath);

      if (!dir.existsSync()) {
        return;
      }

      final newWalletDirPath =
          await pathForWalletDir(name: name, type: getType());

      dir.listSync().forEach((f) {
        final file = File(f.path);
        final name = f.path.split('/').last;
        final newPath = newWalletDirPath + '/$name';
        final newFile = File(newPath);

        if (!newFile.existsSync()) {
          newFile.createSync();
        }
        newFile.writeAsBytesSync(file.readAsBytesSync());
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
