import 'dart:io';

import 'package:collection/collection.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';
import 'package:hive/hive.dart';

abstract class EVMChainWalletService<T extends EVMChainWallet> extends WalletService<
    EVMChainNewWalletCredentials,
    EVMChainRestoreWalletFromSeedCredentials,
    EVMChainRestoreWalletFromPrivateKey> {
  EVMChainWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  @override
  WalletType getType();

  @override
  Future<T> create(EVMChainNewWalletCredentials credentials, {bool? isTestnet});

  @override
  Future<T> openWallet(String name, String password);

  @override
  Future<void> rename(String currentName, String password, String newName);

  @override
  Future<T> restoreFromKeys(EVMChainRestoreWalletFromPrivateKey credentials, {bool? isTestnet});

  @override
  Future<T> restoreFromSeed(EVMChainRestoreWalletFromSeedCredentials credentials, {bool? isTestnet});

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
