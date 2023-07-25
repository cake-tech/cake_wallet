import 'dart:io';

import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
// import 'package:cw_nano/nano_mnemonics.dart';
import 'package:cw_nano/nano_wallet.dart';
import 'package:cw_nano/nano_wallet_creation_credentials.dart';
import 'package:hive/hive.dart';
import 'package:bip39/bip39.dart' as bip39;

class NanoNewWalletCredentials extends WalletCredentials {
  NanoNewWalletCredentials({required String name, String? password})
      : super(name: name, password: password);
}

class NanoRestoreWalletFromSeedCredentials extends WalletCredentials {
  NanoRestoreWalletFromSeedCredentials(
      {required String name, required this.mnemonic, int height = 0, String? password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
}

class NanoWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class NanoRestoreWalletFromKeysCredentials extends WalletCredentials {
  NanoRestoreWalletFromKeysCredentials(
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

class NanoWalletService extends WalletService<NanoNewWalletCredentials,
    NanoRestoreWalletFromSeedCredentials, NanoRestoreWalletFromKeysCredentials> {
  NanoWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.nano;

  @override
  Future<WalletBase> create(NanoNewWalletCredentials credentials) async {
    print("nano_wallet_service create");
    final mnemonic = bip39.generateMnemonic();
    final wallet = NanoWallet(
      walletInfo: credentials.walletInfo!,
      mnemonic: mnemonic,
      password: credentials.password!,
    );
    return wallet;
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
  Future<void> rename(String currentName, String password, String newName) async {
    // final currentWalletInfo = walletInfoSource.values
    //     .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));
    // final currentWallet = NanoWallet(walletInfo: currentWalletInfo);

    // await currentWallet.renameWalletFiles(newName);

    // final newWalletInfo = currentWalletInfo;
    // newWalletInfo.id = WalletBase.idFor(newName, getType());
    // newWalletInfo.name = newName;

    // await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<NanoWallet> restoreFromKeys(NanoRestoreWalletFromKeysCredentials credentials) async {
    print("a");
    throw UnimplementedError();
    // try {
    //   final path = await pathForWallet(name: credentials.name, type: getType());
    //   await monero_wallet_manager.restoreFromKeys(
    //       path: path,
    //       password: credentials.password!,
    //       language: credentials.language,
    //       restoreHeight: credentials.height!,
    //       address: credentials.address,
    //       viewKey: credentials.viewKey,
    //       spendKey: credentials.spendKey);
    //   final wallet = NanoWallet(walletInfo: credentials.walletInfo!);
    //   await wallet.init();

    //   return wallet;
    // } catch (e) {
    //   // TODO: Implement Exception for wallet list service.
    //   print('NanoWalletsManager Error: $e');
    //   rethrow;
    // }
  }

  @override
  Future<NanoWallet> restoreFromSeed(NanoRestoreWalletFromSeedCredentials credentials) async {
    print("b");
    throw UnimplementedError();
    // try {
    //   final path = await pathForWallet(name: credentials.name, type: getType());
    //   await monero_wallet_manager.restoreFromSeed(
    //       path: path,
    //       password: credentials.password!,
    //       seed: credentials.mnemonic,
    //       restoreHeight: credentials.height!);
    //   final wallet = NanoWallet(walletInfo: credentials.walletInfo!);
    //   await wallet.init();

    //   return wallet;
    // } catch (e) {
    //   // TODO: Implement Exception for wallet list service.
    //   print('NanoWalletsManager Error: $e');
    //   rethrow;
    // }
  }

  @override
  Future<bool> isWalletExit(String s) async {
    print("c");
    throw UnimplementedError();
  }

  @override
  Future<WalletBase> openWallet(String s, String s2) async {
    print("d");
    throw UnimplementedError();
  }
}
