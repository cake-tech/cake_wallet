import 'dart:io';
import 'package:collection/collection.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:hive/hive.dart';
import 'package:cw_zano/api/wallet_manager.dart' as zano_wallet_manager;
import 'package:cw_zano/api/wallet.dart' as zano_wallet;
import 'package:cw_zano/api/calls.dart' as calls;
import 'package:cw_zano/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

class ZanoNewWalletCredentials extends WalletCredentials {
  ZanoNewWalletCredentials({required String name, String? password})
      : super(name: name, password: password);
}

class ZanoRestoreWalletFromSeedCredentials extends WalletCredentials {
  ZanoRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required int height,
      required this.mnemonic})
      : super(name: name, password: password, height: height);

  final String mnemonic;
}

class ZanoWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class ZanoRestoreWalletFromKeysCredentials extends WalletCredentials {
  ZanoRestoreWalletFromKeysCredentials(
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

class ZanoWalletService extends WalletService<
    ZanoNewWalletCredentials,
    ZanoRestoreWalletFromSeedCredentials,
    ZanoRestoreWalletFromKeysCredentials> {
  ZanoWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  int hWallet = 0;

  @override
  WalletType getType() => WalletType.zano;

  @override
  Future<ZanoWallet> create(ZanoNewWalletCredentials credentials) async {
    try {
      final wallet = ZanoWallet.simple(walletInfo: credentials.walletInfo!);
      wallet.connectToNode(node: Node());
      final path = await pathForWallet(name: credentials.name, type: getType());
      final result = await zano_wallet_manager.createWallet(
          language: "", path: path, password: credentials.password!);
      hWallet = -1; 
      wallet.hWallet = hWallet;
      // TODO: remove it
      calls.store(hWallet);
      await wallet.init();
      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('ZanoWalletsManager Error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name, type: getType());
      return zano_wallet_manager.isWalletExist(path: path);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('ZanoWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<ZanoWallet> openWallet(String name, String password) async {
    try {
      final path = await pathForWallet(name: name, type: getType());

      if (walletFilesExist(path)) {
        await repairOldAndroidWallet(name);
      }

      await zano_wallet_manager
          .openWalletAsync({'path': path, 'password': password});
      final walletInfo = walletInfoSource.values.firstWhereOrNull(
          (info) => info.id == WalletBase.idFor(name, getType()))!;
      final wallet = ZanoWallet(walletInfo: walletInfo);
      /*final isValid = wallet.walletAddresses.validate();

      if (!isValid) {
        await restoreOrResetWalletFiles(name);
        wallet.close();
        return openWallet(name, password);
      }*/

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
    final currentWallet = ZanoWallet(walletInfo: currentWalletInfo);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<ZanoWallet> restoreFromKeys(
      ZanoRestoreWalletFromKeysCredentials credentials) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await zano_wallet_manager.restoreFromKeys(
          path: path,
          password: credentials.password!,
          language: credentials.language,
          restoreHeight: credentials.height!,
          address: credentials.address,
          viewKey: credentials.viewKey,
          spendKey: credentials.spendKey);
      final wallet = ZanoWallet(walletInfo: credentials.walletInfo!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('ZanoWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<ZanoWallet> restoreFromSeed(
      ZanoRestoreWalletFromSeedCredentials credentials) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await zano_wallet_manager.restoreFromSeed(
          path: path,
          password: credentials.password!,
          seed: credentials.mnemonic,
          restoreHeight: credentials.height!);
      final wallet = ZanoWallet(walletInfo: credentials.walletInfo!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('ZanoWalletsManager Error: $e');
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
