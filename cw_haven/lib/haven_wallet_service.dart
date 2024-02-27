import 'dart:io';
import 'package:collection/collection.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:hive/hive.dart';
import 'package:cw_haven/api/wallet_manager.dart' as haven_wallet_manager;
import 'package:cw_haven/api/wallet.dart' as haven_wallet;
import 'package:cw_haven/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_haven/haven_wallet.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

class HavenNewWalletCredentials extends WalletCredentials {
  HavenNewWalletCredentials({required String name, required this.language, String? password})
      : super(name: name, password: password);

  final String language;
}

class HavenRestoreWalletFromSeedCredentials extends WalletCredentials {
  HavenRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required int height,
      required this.mnemonic})
      : super(name: name, password: password, height: height);

  final String mnemonic;
}

class HavenWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class HavenRestoreWalletFromKeysCredentials extends WalletCredentials {
  HavenRestoreWalletFromKeysCredentials(
      {required String name,
      required String password,
      required this.language,
      required this.address,
      required this.viewKey,
      required this.spendKey,
      required int height})
      : super(name: name, password: password, height: height);

  final String language;
  final String address;
  final String viewKey;
  final String spendKey;
}

class HavenWalletService extends WalletService<
    HavenNewWalletCredentials,
    HavenRestoreWalletFromSeedCredentials,
    HavenRestoreWalletFromKeysCredentials> {
  HavenWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;
  
  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.haven;

  @override
  Future<HavenWallet> create(HavenNewWalletCredentials credentials, {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await haven_wallet_manager.createWallet(
          path: path,
          password: credentials.password!,
          language: credentials.language);
      final wallet = HavenWallet(walletInfo: credentials.walletInfo!);
      await wallet.init();
      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('HavenWalletsManager Error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name, type: getType());
      return haven_wallet_manager.isWalletExist(path: path);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('HavenWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<HavenWallet> openWallet(String name, String password) async {
    try {
      final path = await pathForWallet(name: name, type: getType());

      if (walletFilesExist(path)) {
        await repairOldAndroidWallet(name);
      }

      await haven_wallet_manager
          .openWalletAsync({'path': path, 'password': password});
      final walletInfo = walletInfoSource.values.firstWhereOrNull(
          (info) => info.id == WalletBase.idFor(name, getType()))!;
      final wallet = HavenWallet(walletInfo: walletInfo);
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
    final currentWallet = HavenWallet(walletInfo: currentWalletInfo);

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<HavenWallet> restoreFromKeys(
      HavenRestoreWalletFromKeysCredentials credentials, {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await haven_wallet_manager.restoreFromKeys(
          path: path,
          password: credentials.password!,
          language: credentials.language,
          restoreHeight: credentials.height!,
          address: credentials.address,
          viewKey: credentials.viewKey,
          spendKey: credentials.spendKey);
      final wallet = HavenWallet(walletInfo: credentials.walletInfo!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('HavenWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<HavenWallet> restoreFromSeed(
      HavenRestoreWalletFromSeedCredentials credentials, {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await haven_wallet_manager.restoreFromSeed(
          path: path,
          password: credentials.password!,
          seed: credentials.mnemonic,
          restoreHeight: credentials.height!);
      final wallet = HavenWallet(walletInfo: credentials.walletInfo!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('HavenWalletsManager Error: $e');
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
