import 'dart:io';

import 'package:collection/collection.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:monero/zano.dart' as zano;

class ZanoNewWalletCredentials extends WalletCredentials {
  ZanoNewWalletCredentials({
    required String name,
    String? password,
    required String? passphrase,
    this.mnemonic,
  }) : super(name: name, password: password, passphrase: passphrase);

  final String? mnemonic;
}

class ZanoRestoreWalletFromSeedCredentials extends WalletCredentials {
  ZanoRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required String passphrase,
      required int height,
      required this.mnemonic})
      : super(name: name, password: password, passphrase: passphrase, height: height);

  final String mnemonic;
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
    ZanoRestoreWalletFromKeysCredentials,
    ZanoNewWalletCredentials> {
  ZanoWalletService(this.isDirect);

  final bool isDirect;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  int hWallet = 0;

  @override
  WalletType getType() => WalletType.zano;

  @override
  Future<ZanoWallet> create(WalletCredentials credentials, {bool? isTestnet}) async {
    printV('zanowallet service create isTestnet $isTestnet');
    return await ZanoWalletBase.create(
        credentials: credentials, encryptionFileUtils: encryptionFileUtilsFor(isDirect));
  }

  @override
  Future<bool> isWalletExit(WalletInfo walletInfo) async {
    final path = walletInfo.path;
    return zano.PlainWallet_isWalletExist(path);
  }

  @override
  Future<ZanoWallet> openWallet(WalletInfo walletInfo, String password) async {
    final name = walletInfo.name;

    try {
      final wallet =
          await ZanoWalletBase.open(
              name: name,
              password: password,
              walletInfo: walletInfo,
              encryptionFileUtils: encryptionFileUtilsFor(isDirect));
      saveBackup(walletInfo);
      return wallet;
    } catch (e) {
      printV('openWallet $name failed: $e');
      await restoreWalletFilesFromBackup(walletInfo);
      return await ZanoWalletBase.open(
          name: name,
          password: password,
          walletInfo: walletInfo,
          encryptionFileUtils: encryptionFileUtilsFor(isDirect));
    }
  }

  @override
  Future<void> remove(WalletInfo walletInfo) async {
    await super.remove(walletInfo);
  }

  // @override
  // Future<void> rename(String currentName, String password, String newName) async {
  //   final currentWalletInfo = await WalletInfo.get(currentName, getType());
  //   if (currentWalletInfo == null) {
  //     throw Exception('Wallet not found');
  //   }
  //   final currentWallet =
  //       ZanoWallet(currentWalletInfo, await currentWalletInfo.getDerivationInfo(), password,
  //           encryptionFileUtilsFor(isDirect));
  //
  //   final oldPath = await pathForWallet(name: currentName, type: getType());
  //   final cached = ZanoWalletApi.openWalletCache.remove(oldPath);
  //   if (cached != null) {
  //     currentWallet.hWallet = cached.walletId;
  //     await currentWallet.closeWallet(cached.walletId, force: true);
  //   }
  //
  //   await currentWallet.renameWalletFiles(newName);
  //
  //   final newDirPath = await pathForWalletDir(name: newName, type: getType());
  //   currentWalletInfo.id = WalletBase.idFor(newName, getType());
  //   currentWalletInfo.name = newName;
  //   currentWalletInfo.dirPath = newDirPath;
  //   currentWalletInfo.path = '$newDirPath/$newName';
  //   await currentWalletInfo.save();
  // }

  @override
  Future<ZanoWallet> restoreFromKeys(ZanoRestoreWalletFromKeysCredentials credentials,
      {bool? isTestnet}) async {
    throw UnimplementedError();
  }

  @override
  Future<ZanoWallet> restoreFromSeed(ZanoRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    return ZanoWalletBase.restore(
        credentials: credentials, encryptionFileUtils: encryptionFileUtilsFor(isDirect));
  }

  @override
  Future<ZanoWallet> restoreFromHardwareWallet(ZanoNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a Zano wallet from a hardware wallet is not yet supported!");
  }
}
