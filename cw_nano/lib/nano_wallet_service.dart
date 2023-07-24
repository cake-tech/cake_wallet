import 'dart:io';

import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
// import 'package:cw_nano/nano_mnemonics.dart';
import 'package:cw_nano/nano_wallet.dart';
import 'package:cw_nano/nano_wallet_creation_credentials.dart';
import 'package:hive/hive.dart';
import 'package:bip39/bip39.dart' as bip39;



class NanoWalletService extends WalletService<NanoNewWalletCredentials,
    NanoRestoreWalletFromSeedCredentials, NanoRestoreWalletFromWIFCredentials> {
  NanoWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  @override
  Future<NanoWallet> create(NanoNewWalletCredentials credentials) async {
    final mnemonic = bip39.generateMnemonic();
    final wallet = NanoWallet(
      walletInfo: credentials.walletInfo!,
      mnemonic: mnemonic,
      password: credentials.password!,
    );

    await wallet.init();
    await wallet.save();

    return wallet;
  }

  @override
  WalletType getType() => WalletType.ethereum;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<NanoWallet> openWallet(String name, String password) async {
    final walletInfo =
        walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(name, getType()));
    final wallet = await NanoWalletBase.open(
      name: name,
      password: password,
      walletInfo: walletInfo,
    );

    await wallet.init();
    await wallet.save();

    return wallet;
  }

  @override
  Future<void> remove(String wallet) async =>
      File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);

  @override
  Future<NanoWallet> restoreFromKeys(credentials) {
    throw UnimplementedError();
  }

  @override
  Future<NanoWallet> restoreFromSeed(
      NanoRestoreWalletFromSeedCredentials credentials) async {
    // if (!bip39.validateMnemonic(credentials.mnemonic)) {
    //   throw EthereumMnemonicIsIncorrectException();
    // }

    final wallet = await NanoWallet(
      // password: credentials.password!,
      // mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
    );

    await wallet.init();
    await wallet.save();

    return wallet;
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));
    final currentWallet = await NanoWalletBase.open(
        password: password, name: currentName, walletInfo: currentWalletInfo);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }
}
