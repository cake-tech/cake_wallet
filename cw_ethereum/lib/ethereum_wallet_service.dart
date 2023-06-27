import 'dart:io';

import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_ethereum/ethereum_mnemonics.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:cw_ethereum/ethereum_wallet_creation_credentials.dart';
import 'package:hive/hive.dart';
import 'package:bip39/bip39.dart' as bip39;

class EthereumWalletService extends WalletService<EthereumNewWalletCredentials,
    EthereumRestoreWalletFromSeedCredentials, EthereumRestoreWalletFromWIFCredentials> {
  EthereumWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  @override
  Future<EthereumWallet> create(EthereumNewWalletCredentials credentials) async {
    final mnemonic = bip39.generateMnemonic();
    final wallet = EthereumWallet(
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
  WalletType getType() => WalletType.ethereum;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<EthereumWallet> openWallet(String name, String password) async {
    final walletInfo =
        walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(name, getType()));
    final wallet = await EthereumWalletBase.open(
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
  Future<EthereumWallet> restoreFromKeys(credentials) {
    throw UnimplementedError();
  }

  @override
  Future<EthereumWallet> restoreFromSeed(
      EthereumRestoreWalletFromSeedCredentials credentials) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw EthereumMnemonicIsIncorrectException();
    }

    final wallet = await EthereumWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }
}
