import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_tron/tron_client.dart';
import 'package:cw_tron/tron_exception.dart';
import 'package:cw_tron/tron_wallet.dart';
import 'package:cw_tron/tron_wallet_creation_credentials.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

class TronWalletService extends WalletService<TronNewWalletCredentials,
    TronRestoreWalletFromSeedCredentials, TronRestoreWalletFromPrivateKey> {
  TronWalletService(this.walletInfoSource, {required this.client});

  late TronClient client;

  final Box<WalletInfo> walletInfoSource;

  @override
  WalletType getType() => WalletType.tron;

  @override
  Future<TronWallet> create(
    TronNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final mnemonic = bip39.generateMnemonic(strength: strength);

    final wallet = TronWallet(
      walletInfo: credentials.walletInfo!,
      mnemonic: mnemonic,
      password: credentials.password!,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<TronWallet> openWallet(String name, String password) async {
    final walletInfo =
        walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(name, getType()));

    try {
      final wallet = await TronWalletBase.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
      );

      await wallet.init();
      await wallet.save();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);

      final wallet = await TronWalletBase.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
      );

      await wallet.init();
      await wallet.save();
      return wallet;
    }
  }

  @override
  Future<TronWallet> restoreFromKeys(
    TronRestoreWalletFromPrivateKey credentials, {
    bool? isTestnet,
  }) async {
    final wallet = TronWallet(
      password: credentials.password!,
      privateKey: credentials.privateKey,
      walletInfo: credentials.walletInfo!,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<TronWallet> restoreFromSeed(
    TronRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw TronMnemonicIsIncorrectException();
    }

    final wallet = TronWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));
    final currentWallet = await TronWalletBase.open(
        password: password, name: currentName, walletInfo: currentWalletInfo);

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(wallet, getType()))!;
    await walletInfoSource.delete(walletInfo.key);
  }
}
