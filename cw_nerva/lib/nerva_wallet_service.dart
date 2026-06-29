import 'dart:ffi';
import 'dart:io';
import 'package:cw_core/exceptions.dart' show WalletDeprecationException;
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_nerva/api/account_list.dart';
import 'package:cw_nerva/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_nerva/api/wallet_manager.dart' as nerva_wallet_manager;
import 'package:cw_nerva/api/wallet_manager.dart';
import 'package:cw_nerva/nerva_wallet.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:monero/nerva.dart' as nerva;

class NervaNewWalletCredentials extends WalletCredentials {
  NervaNewWalletCredentials(
      {required String name, required this.language, this.passphrase, String? password})
      : super(name: name, password: password);

  final String language;
  final String? passphrase;
}

class NervaRestoreWalletFromSeedCredentials extends WalletCredentials {
  NervaRestoreWalletFromSeedCredentials(
      {required String name, required this.mnemonic, required this.passphrase, int height = 0, String? password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
  final String passphrase;
}

class NervaWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class NervaRestoreWalletFromKeysCredentials extends WalletCredentials {
  NervaRestoreWalletFromKeysCredentials(
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

class NervaWalletService extends WalletService<
    NervaNewWalletCredentials,
    NervaRestoreWalletFromSeedCredentials,
    NervaRestoreWalletFromKeysCredentials,
    NervaNewWalletCredentials> {
  NervaWalletService(this.unspentCoinsInfoSource);

  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.nerva;

  @override
  Future<NervaWallet> create(NervaNewWalletCredentials credentials, {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());

      await nerva_wallet_manager.createWallet(
          path: path, password: credentials.password!, language: credentials.language, passphrase: credentials.passphrase??'');
      final wallet = NervaWallet(
          walletInfo: credentials.walletInfo!, derivationInfo: await credentials.walletInfo!.getDerivationInfo(), unspentCoinsInfo: unspentCoinsInfoSource, password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('NervaWalletsManager Error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name, type: getType());
      return nerva_wallet_manager.isWalletExist(path: path);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('NervaWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<NervaWallet> openWallet(String name, String password) async {
    NervaWallet? wallet;
    try {
      final path = await pathForWallet(name: name, type: getType());

      if (walletFilesExist(path)) {
        await repairOldAndroidWallet(name);
      }

      await nerva_wallet_manager.openWalletAsync({'path': path, 'password': password});
      final walletInfo = await WalletInfo.get(name, getType());
      if (walletInfo == null) {
        throw Exception('Wallet not found');
      }

      wallet = NervaWallet(walletInfo: walletInfo, derivationInfo: await walletInfo.getDerivationInfo(), unspentCoinsInfo: unspentCoinsInfoSource, password: password);
      throw WalletDeprecationException(seed: wallet.seed, curr: wallet.currency);

      final isValid = wallet.walletAddresses.validate();

      if (!isValid) {
        await restoreOrResetWalletFiles(name);
        wallet.close(shouldCleanup: false);
        return openWallet(name, password);
      }

      await wallet.init();
      return wallet;
    } catch (e, s) {
      rethrow;
      // TODO: Implement Exception for wallet list service.

      final bool isBadAlloc = e.toString().contains('bad_alloc') ||
          (e is WalletOpeningException &&
              (e.message == 'std::bad_alloc' || e.message.contains('bad_alloc')));

      final bool doesNotCorrespond = e.toString().contains('does not correspond') ||
          (e is WalletOpeningException && e.message.contains('does not correspond'));

      final bool isMissingCacheFilesIOS = e.toString().contains('basic_string') ||
          (e is WalletOpeningException && e.message.contains('basic_string'));

      final bool isMissingCacheFilesAndroid = e.toString().contains('input_stream') ||
          e.toString().contains('input stream error') ||
          (e is WalletOpeningException &&
              (e.message.contains('input_stream') || e.message.contains('input stream error')));

      final bool invalidSignature = e.toString().contains('invalid signature') ||
          (e is WalletOpeningException && e.message.contains('invalid signature'));

      if (!isBadAlloc &&
          !doesNotCorrespond &&
          !isMissingCacheFilesIOS &&
          !isMissingCacheFilesAndroid &&
          !invalidSignature &&
          wallet != null &&
          wallet.onError != null) {
        wallet.onError!(FlutterErrorDetails(exception: e, stack: s));
      }

      await restoreOrResetWalletFiles(name);
      return openWallet(name, password);
    }
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    if (openedWalletsByPath["$path/$wallet"] != null) {
      // NOTE: this is realistically only required on windows.
      printV("closing wallet");
      final wmaddr = wmPtr.address;
      final waddr = openedWalletsByPath["$path/$wallet"]!.address;
      // await Isolate.run(() {
      nerva.WalletManager_closeWallet(
          Pointer.fromAddress(wmaddr), Pointer.fromAddress(waddr), false);
      // });
      openedWalletsByPath.remove("$path/$wallet");
      printV("wallet closed");
    }

    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }

    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }
    final currentWallet = NervaWallet(walletInfo: currentWalletInfo, derivationInfo: await currentWalletInfo.getDerivationInfo(), unspentCoinsInfo: unspentCoinsInfoSource, password: password);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await newWalletInfo.save();
  }

  @override
  Future<NervaWallet> restoreFromKeys(NervaRestoreWalletFromKeysCredentials credentials,
      {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await nerva_wallet_manager.restoreFromKeys(
          path: path,
          password: credentials.password!,
          language: credentials.language,
          restoreHeight: credentials.height!,
          address: credentials.address,
          viewKey: credentials.viewKey,
          spendKey: credentials.spendKey);
      final wallet = NervaWallet(
          walletInfo: credentials.walletInfo!, derivationInfo: await credentials.walletInfo!.getDerivationInfo(), unspentCoinsInfo: unspentCoinsInfoSource, password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('NervaWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<NervaWallet> restoreFromHardwareWallet(NervaNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a Nerva wallet from a hardware wallet is not yet supported!");
  }

  @override
  Future<NervaWallet> restoreFromSeed(NervaRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      await nerva_wallet_manager.restoreFromSeed(
          path: path,
          password: credentials.password!,
          passphrase: credentials.passphrase,
          seed: credentials.mnemonic,
          restoreHeight: credentials.height!);
      final wallet = NervaWallet(
          walletInfo: credentials.walletInfo!, derivationInfo: await credentials.walletInfo!.getDerivationInfo(), unspentCoinsInfo: unspentCoinsInfoSource, password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('NervaWalletsManager Error: $e');
      rethrow;
    }
  }

  Future<void> repairOldAndroidWallet(String name) async {
    try {
      if (!Platform.isAndroid) {
        return;
      }

      final oldAndroidWalletDirPath = await outdatedAndroidPathForWalletDir(name: name);
      final dir = Directory(oldAndroidWalletDirPath);

      if (!dir.existsSync()) {
        return;
      }

      final newWalletDirPath = await pathForWalletDir(name: name, type: getType());

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
      printV(e.toString());
    }
  }
}
