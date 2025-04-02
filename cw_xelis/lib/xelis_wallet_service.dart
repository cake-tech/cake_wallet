import 'dart:io';

import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_xelis/xelis_wallet.dart';
import 'package:cw_xelis/xelis_transaction_info.dart';
import 'package:cw_xelis/xelis_table_storage.dart';
import 'package:cw_xelis/src/api/network.dart';
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;
import 'package:cw_xelis/xelis_wallet_creation_credentials.dart';
import 'package:collection/collection.dart';

class XelisWalletService extends WalletService<
  XelisNewWalletCredentials,
  XelisRestoreWalletFromSeedCredentials
> {
  XelisWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  @override
  WalletType getType() => WalletType.xelis;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWalletDir(name: name, type: getType())).existsSync();

  Future<String> _getTablePath() async {
    final root = await getAppDir();
    final prefix = walletTypeToString(getType()).toLowerCase();
    final tablesDir = Directory('${root.path}/wallets/$prefix/tables');

    if (!tablesDir.existsSync()) {
      tablesDir.createSync(recursive: true);
    }

    return tablesDir.path;
  }

  Network _resolveNetwork({bool? isTestnet}) =>
      isTestnet == true ? Network.testnet : Network.mainnet;

  @override
  Future<XelisWallet> create(XelisNewWalletCredentials credentials, {bool? isTestnet}) async {
    final fullPath = await pathForWalletDir(name: credentials.name, type: getType());
    final tablePath = await _getTablePath();
    final tableState = await getTableState();

    final network = _resolveNetwork(isTestnet: isTestnet);

    final frbWallet = await x_wallet.createXelisWallet(
      name: fullPath,
      directory: "",
      password: credentials.password ?? '',
      network: network,
      precomputedTablesPath: tablePath,
      l1Low: tableState.currentSize.isLow,
    );

    final walletInfo = credentials.walletInfo!;
    walletInfo.address = frbWallet.getAddressStr();
    walletInfo.network = network.name;

    final wallet = XelisWallet(walletInfo: walletInfo, wallet: frbWallet);
    await wallet.init();
    return wallet;
  }

  @override
  Future<XelisWallet> openWallet(String name, String password, {bool? isTestnet}) async {
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(name, getType()))!;

    final fullPath = await pathForWalletDir(name: name, type: getType());
    final tablePath = await _getTablePath();
    final tableState = await getTableState();
    final network = _resolveNetwork(isTestnet: isTestnet);

    try {
      final frbWallet = await x_wallet.openXelisWallet(
        name: fullPath,
        directory: "",
        password: password,
        network: network,
        precomputedTablesPath: tablePath,
        l1Low: tableState.currentSize.isLow,
      );

      final wallet = XelisWallet(walletInfo: walletInfo, wallet: frbWallet);
      await wallet.init();
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);

      final frbWallet = await x_wallet.openXelisWallet(
        name: fullPath,
        directory: "",
        password: password,
        network: network,
        precomputedTablesPath: tablePath,
        l1Low: tableState.currentSize.isLow,
      );

      final wallet = XelisWallet(walletInfo: walletInfo, wallet: frbWallet);
      await wallet.init();
      return wallet;
    }
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));

    final fullPath = await pathForWalletDir(name: currentName, type: getType());
    final tablePath = await _getTablePath();
    final tableState = await getTableState();
    final network = _resolveNetwork(
      isTestnet: currentWalletInfo.network == Network.testnet.name,
    );

    final frbWallet = await x_wallet.openXelisWallet(
      name: fullPath,
      directory: "",
      password: password,
      network: network,
      precomputedTablesPath: tablePath,
      l1Low: tableState.currentSize.isLow,
    );

    final wallet = XelisWallet(walletInfo: currentWalletInfo, wallet: frbWallet);
    final newPath = await pathForWalletDir(name: newName, type: getType());
    final newDir = Directory(newPath);
    final exists = await newDir.exists();
    if (exists) {
      throw 'A wallet with this name already exists.';
    }

    await Directory(fullPath).rename(newPath);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;
    newWalletInfo.dirPath = await pathForWalletDir(name: newName, type: getType());

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).deleteSync(recursive: true);

    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(wallet, getType()));

    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<XelisWallet> restoreFromSeed(XelisRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    final fullPath = await pathForWalletDir(name: credentials.name, type: getType());
    final tablePath = await _getTablePath();
    final tableState = await getTableState();
    final network = _resolveNetwork(isTestnet: isTestnet);

    final frbWallet = await x_wallet.createXelisWallet(
      name: fullPath,
      directory: "",
      password: credentials.password ?? '',
      seed: credentials.mnemonic,
      network: network,
      precomputedTablesPath: tablePath,
      l1Low: tableState.currentSize.isLow,
    );

    final walletInfo = credentials.walletInfo!;
    walletInfo.address = frbWallet.getAddressStr();
    walletInfo.network = network.name;
    await walletInfo.save();

    final wallet = XelisWallet(walletInfo: walletInfo, wallet: frbWallet);
    await wallet.init();
    return wallet;
  }
}
