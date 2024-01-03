import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:collection/collection.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/evm_chain_mnemonics.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';
import 'package:hive/hive.dart';

class EVMChainWalletService extends WalletService<EVMChainNewWalletCredentials,
    EVMChainRestoreWalletFromSeedCredentials, EVMChainRestoreWalletFromPrivateKey> {
  EVMChainWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  @override
  Future<EVMChainWallet> create(EVMChainNewWalletCredentials credentials) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final mnemonic = bip39.generateMnemonic(strength: strength);

    final nativeCurrency = currencyForWalletType(credentials.walletInfo!.type);

    final wallet = EVMChainWallet(
      walletInfo: credentials.walletInfo!,
      mnemonic: mnemonic,
      password: credentials.password!,
      nativeCurrency: nativeCurrency,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  WalletType getType() => WalletType.ethereum;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<EVMChainWallet> openWallet(String name, String password) async {
    final walletInfo =
        walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(name, getType()));
    final wallet = await EVMChainWalletBase.open(
      name: name,
      password: password,
      walletInfo: walletInfo,
    );

    await wallet.init();
    await wallet.save();

    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(wallet, getType()))!;
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<EVMChainWallet> restoreFromKeys(EVMChainRestoreWalletFromPrivateKey credentials) async {
    final nativeCurrency = currencyForWalletType(credentials.walletInfo!.type);

    final wallet = EVMChainWallet(
      password: credentials.password!,
      privateKey: credentials.privateKey,
      walletInfo: credentials.walletInfo!,
      nativeCurrency: nativeCurrency,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<EVMChainWallet> restoreFromSeed(
      EVMChainRestoreWalletFromSeedCredentials credentials) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw EVMChainMnemonicIsIncorrectException();
    }

    final nativeCurrency = currencyForWalletType(credentials.walletInfo!.type);

    final wallet = EVMChainWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      nativeCurrency: nativeCurrency,
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
    final currentWallet = await EVMChainWalletBase.open(
        password: password, name: currentName, walletInfo: currentWalletInfo);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }
}
