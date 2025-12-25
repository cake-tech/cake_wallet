import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zcash/cw_zcash.dart';

class ZcashWalletService extends WalletService<ZcashNewWalletCredentials,
    ZcashFromSeedWalletCredentials, ZcashFromKeysWalletCredentials, ZcashNewWalletCredentials> {
  ZcashWalletService();

  static bool walletFilesExist(String path) => !File(path).existsSync() && !File('$path.keys').existsSync();

  int hWallet = 0;

  @override
  WalletType getType() => WalletType.zcash;

  @override
  Future<ZcashWallet> create(WalletCredentials credentials, {bool? isTestnet}) async {
    return ZcashWalletBase.create(credentials);
  }

  @override
  Future<bool> isWalletExit(String name) async {
    final path = await pathForWallet(name: name, type: getType());
    return File(path).existsSync();
  }

  @override
  Future<ZcashWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    try {
      final wallet = await ZcashWalletBase.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
      );
      await wallet.init();
      saveBackup(name);
      return wallet;
    } catch (e) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await ZcashWalletBase.open(name: name, password: password, walletInfo: walletInfo);
      await wallet.init();
      return wallet;
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
    final accountId = await ZcashWalletBase.getZcashAccountIdForName(currentName);
    if (accountId == null) {
      throw Exception('Wallet account not found for name: $currentName');
    }
    final currentWallet = ZcashWallet(
        currentWalletInfo,
        await currentWalletInfo.getDerivationInfo(),
        accountId: accountId,
    );

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await newWalletInfo.save();
  }

  @override
  Future<ZcashWallet> restoreFromKeys(ZcashFromKeysWalletCredentials credentials, {bool? isTestnet}) async {
    throw UnimplementedError();
  }

  @override
  Future<ZcashWallet> restoreFromSeed(ZcashFromSeedWalletCredentials credentials, {bool? isTestnet}) async {
    if (credentials.seed == null || credentials.seed!.isEmpty) {
      throw ZcashMnemonicIsIncorrectException();
    }
    
    if (!bip39.validateMnemonic(credentials.seed!)) {
      throw ZcashMnemonicIsIncorrectException();
    }
    
    return ZcashWalletBase.restore(credentials);
  }

  @override
  Future<ZcashWallet> restoreFromHardwareWallet(ZcashNewWalletCredentials credentials) {
    throw UnimplementedError("Restoring a Zcash wallet from a hardware wallet is not yet supported!");
  }
}
