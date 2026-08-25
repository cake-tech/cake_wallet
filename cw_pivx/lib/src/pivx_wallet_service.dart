import 'dart:io';

import 'package:bip39/bip39.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_pivx/cw_pivx.dart';
import 'package:hive/hive.dart';

class PivxWalletService extends WalletService<
    PivxNewWalletCredentials,
    PivxRestoreWalletFromSeedCredentials,
    PivxRestoreWalletFromWIFCredentials,
    PivxNewWalletCredentials> {
  PivxWalletService(this.unspentCoinsInfoSource, this.isDirect);

  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  final bool isDirect;

  @override
  WalletType getType() => WalletType.pivx;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<PivxWallet> create(credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;
    credentials.walletInfo!.network =
        (isTestnet ?? false) ? 'testnet' : 'mainnet';

    final wallet = await PivxWalletBase.create(
      mnemonic:
          credentials.mnemonic ?? MnemonicBip39.generate(strength: strength),
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      passphrase: credentials.passphrase,
      isTestnet: isTestnet ?? false,
    );
    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<PivxWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    try {
      final wallet = await PivxWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
        isTestnet: walletInfo.network == 'testnet',
      );
      await wallet.init();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await PivxWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
        isTestnet: walletInfo.network == 'testnet',
      );
      await wallet.init();
      return wallet;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType()))
        .delete(recursive: true);
    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);

    final unspentCoinsToDelete = unspentCoinsInfoSource.values
        .where((unspentCoin) => unspentCoin.walletId == walletInfo.id)
        .toList();

    final keysToDelete =
        unspentCoinsToDelete.map((unspentCoin) => unspentCoin.key).toList();

    if (keysToDelete.isNotEmpty) {
      await unspentCoinsInfoSource.deleteAll(keysToDelete);
    }
  }

  @override
  Future<void> rename(
      String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }
    final currentWallet = await PivxWalletBase.open(
      password: password,
      name: currentName,
      walletInfo: currentWalletInfo,
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      isTestnet: currentWalletInfo.network == 'testnet',
    );

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await newWalletInfo.save();
  }

  @override
  Future<PivxWallet> restoreFromHardwareWallet(
      PivxNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a PIVX wallet from a hardware wallet is not yet supported!");
  }

  @override
  Future<PivxWallet> restoreFromKeys(
      PivxRestoreWalletFromWIFCredentials credentials,
      {bool? isTestnet}) {
    throw UnimplementedError(
        "PIVX wallets restore from a seed phrase; WIF key import is not supported!");
  }

  @override
  Future<PivxWallet> restoreFromSeed(
    PivxRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw Exception('Invalid PIVX mnemonic');
    }
    credentials.walletInfo!.network =
        (isTestnet ?? false) ? 'testnet' : 'mainnet';

    final wallet = await PivxWalletBase.create(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      passphrase: credentials.passphrase,
      isTestnet: isTestnet ?? false,
    );
    await wallet.save();
    await wallet.init();
    return wallet;
  }
}
