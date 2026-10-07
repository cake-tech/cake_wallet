import 'dart:io';

import 'package:bip39/bip39.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_dash/cw_dash.dart';
import 'package:hive/hive.dart';

class DashWalletService extends WalletService<DashNewWalletCredentials,
    DashRestoreWalletFromSeedCredentials, WalletCredentials, DashNewWalletCredentials> {
  DashWalletService(this.unspentCoinsInfoSource, this.isDirect);

  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  final bool isDirect;

  @override
  WalletType getType() => WalletType.dash;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<DashWallet> create(credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final wallet = await DashWalletBase.create(
      mnemonic: credentials.mnemonic ?? MnemonicBip39.generate(strength: strength),
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      passphrase: credentials.passphrase,
    );
    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<DashWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    try {
      final wallet = await DashWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await DashWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      return wallet;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);

    final unspentCoinsToDelete = unspentCoinsInfoSource.values
        .where((unspentCoin) => unspentCoin.walletId == walletInfo.id)
        .toList();

    final keysToDelete = unspentCoinsToDelete.map((unspentCoin) => unspentCoin.key).toList();

    if (keysToDelete.isNotEmpty) {
      await unspentCoinsInfoSource.deleteAll(keysToDelete);
    }
  }

  @override
  Future<DashWallet> restoreFromHardwareWallet(DashNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a Dash wallet from a hardware wallet is not yet supported!");
  }

  @override
  Future<DashWallet> restoreFromKeys(credentials, {bool? isTestnet}) {
    // TODO: implement restoreFromKeys
    throw UnimplementedError('restoreFromKeys() is not implemented');
  }

  @override
  Future<DashWallet> restoreFromSeed(DashRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw Exception('Invalid mnemonic: ${credentials.mnemonic}');
    }

    final wallet = await DashWalletBase.create(
        password: credentials.password!,
        mnemonic: credentials.mnemonic,
        walletInfo: credentials.walletInfo!,
        derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
        passphrase: credentials.passphrase);
    await wallet.save();
    await wallet.init();
    return wallet;
  }
}
