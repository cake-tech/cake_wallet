import 'dart:io';
import 'dart:async';

import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/root_dir.dart';

import 'package:cw_xelis/xelis_wallet.dart';
import 'package:cw_xelis/src/api/network.dart';
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;
import 'package:cw_xelis/xelis_wallet_creation_credentials.dart';

import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

import 'package:mutex/mutex.dart';

enum XelisTableSize {
  low,
  full,
  none;

  bool get isLow => this == XelisTableSize.low;

  static XelisTableSize get platformDefault {
    if (kIsWeb) {
      return XelisTableSize.low;
    }
    return XelisTableSize.full;
  }
}

class XelisTableState {
  final XelisTableSize currentSize;
  final XelisTableSize _desiredSize;

  XelisTableSize get desiredSize {
    if (kIsWeb) {
      return XelisTableSize.low;
    }
    return _desiredSize;
  }

  get isFull => currentSize == XelisTableSize.full;

  const XelisTableState({
    this.currentSize = XelisTableSize.low,
    XelisTableSize desiredSize = XelisTableSize.full,
  }) : _desiredSize = desiredSize;

  XelisTableState copyWith({
    XelisTableSize? currentSize,
    XelisTableSize? desiredSize,
  }) {
    return XelisTableState(
      currentSize: currentSize ?? this.currentSize,
      desiredSize: kIsWeb ? XelisTableSize.low : (desiredSize ?? _desiredSize),
    );
  }

  factory XelisTableState.fromJson(Map<String, dynamic> json) {
    return XelisTableState(
      currentSize: XelisTableSize.values[json['currentSize'] as int],
      desiredSize: XelisTableSize.values[json['desiredSize'] as int],
    );
  }

  Map<String, dynamic> toJson() => {
    'currentSize': currentSize.index,
    'desiredSize': _desiredSize.index,
  };
}

class XelisWalletService extends WalletService<
  XelisNewWalletCredentials,
  XelisRestoreWalletFromSeedCredentials, // TODO: add view key credentials when supported by Xelis
  XelisNewWalletCredentials,
  XelisNewWalletCredentials
> {
  XelisWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  static bool isGenerating = false;
  static final _tableUpgradeMutex = Mutex();
  static Completer<void>? _tableUpgradeCompleter;

  @override
  WalletType getType() => WalletType.xelis;

  @override
  Future<bool> isWalletExit(String name) async =>
      await File(await pathForWalletDir(name: name, type: getType())).exists();

  Future<XelisTableState> _getTableState() async {
    final tablesPath = await _getTablePath();
    final tablesDir = Directory(tablesPath);

    final files = await tablesDir.list().toList();
    final hasFullTables = files.any((file) => file.path.contains('full')); // Adjust based on your file naming
    final hasLowTables = files.isNotEmpty;

    final currentSize = hasFullTables
        ? XelisTableSize.full
        : hasLowTables
            ? XelisTableSize.low
            : XelisTableSize.none;

    final desiredSize = isGenerating ? XelisTableSize.full : currentSize;

    return XelisTableState(
      currentSize: currentSize,
      desiredSize: desiredSize,
    );
  }

  Future<String> _getTablePath() async {
    final root = await getAppDir();
    final prefix = walletTypeToString(getType()).toLowerCase();
    final tablesDir = Directory('${root.path}/wallets/$prefix/tables');

    if (!await tablesDir.exists()) {
      await tablesDir.create(recursive: true);
    }

    return tablesDir.path;
  }

  @override
  Future<XelisWallet> create(XelisNewWalletCredentials credentials, {bool? isTestnet}) async {
    final fullPath = await pathForWalletDir(name: credentials.name, type: getType());
    final tableState = await _getTableState();
    final tablesRoot = await _getTablePath();

    final selectedTableSubdir = tableState.isFull ? 'full' : 'low';
    final selectedTablePath = '$tablesRoot/$selectedTableSubdir';
    
    final network = isTestnet == true ? Network.testnet : Network.mainnet;

    final frbWallet = await x_wallet.createXelisWallet(
      name: fullPath,
      directory: "",
      password: credentials.password!,
      network: network,
      precomputedTablesPath: selectedTablePath,
      l1Low: tableState.currentSize.isLow,
    );

    final walletInfo = credentials.walletInfo!;
    walletInfo.address = frbWallet.getAddressStr();
    walletInfo.network = network.name;

    final wallet = XelisWallet(walletInfo: walletInfo, libWallet: frbWallet, password: credentials.password!);
    unawaited(_upgradeTablesIfNeeded());
    return wallet;
  }

  @override
  Future<XelisWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(name, getType()))!;

    final fullPath = await pathForWalletDir(name: name, type: getType());
    final tableState = await _getTableState();
    final tablesRoot = await _getTablePath();

    final selectedTableSubdir = tableState.isFull ? 'full' : 'low';
    final selectedTablePath = '$tablesRoot/$selectedTableSubdir';
    
    final network = NetworkName.fromName(walletInfo!.network!);

    try {
      final frbWallet = await x_wallet.openXelisWallet(
        name: fullPath,
        directory: "",
        password: password,
        network: network,
        precomputedTablesPath: selectedTablePath,
        l1Low: tableState.currentSize.isLow,
      );

      final wallet = XelisWallet(walletInfo: walletInfo, libWallet: frbWallet, password: password);
      unawaited(_upgradeTablesIfNeeded());
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);

      final frbWallet = await x_wallet.openXelisWallet(
        name: fullPath,
        directory: "",
        password: password,
        network: network,
        precomputedTablesPath: selectedTablePath,
        l1Low: tableState.currentSize.isLow,
      );

      final wallet = XelisWallet(walletInfo: walletInfo, libWallet: frbWallet, password: password);
      unawaited(_upgradeTablesIfNeeded());
      return wallet;
    }
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));

    final fullPath = await pathForWalletDir(name: currentName, type: getType());
    
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
  Future<XelisWallet> restoreFromSeed(XelisRestoreWalletFromSeedCredentials credentials, {bool? isTestnet}) async {
    final fullPath = await pathForWalletDir(name: credentials.walletInfo!.name, type: getType());
    final tableState = await _getTableState();
    final tablesRoot = await _getTablePath();

    final selectedTableSubdir = tableState.isFull ? 'full' : 'low';
    final selectedTablePath = '$tablesRoot/$selectedTableSubdir';
    final network = isTestnet == true ? Network.testnet : Network.mainnet;

    final frbWallet = await x_wallet.createXelisWallet(
      name: fullPath,
      directory: "",
      password: credentials.password!,
      seed: credentials.mnemonic,
      network: network,
      precomputedTablesPath: selectedTablePath,
      l1Low: tableState.currentSize.isLow,
    );

    final walletInfo = credentials.walletInfo!;
    walletInfo.address = frbWallet.getAddressStr();
    walletInfo.network = network.name;
    await walletInfo.save();

    final wallet = XelisWallet(walletInfo: walletInfo, libWallet: frbWallet, password: credentials.password!);
    unawaited(_upgradeTablesIfNeeded());
    return wallet;
  }

  Future<void> _upgradeTablesIfNeeded() async {
    if (isGenerating || kIsWeb) return;

    if (_tableUpgradeCompleter != null) {
      try {
        await _tableUpgradeCompleter!.future;
        return;
      } catch (_) {
        // Previous upgrade failed, try again
      }
    }

    await _tableUpgradeMutex.protect(() async {
      if (_tableUpgradeCompleter != null) {
        try {
          await _tableUpgradeCompleter!.future;
          return;
        } catch (_) {}
      }

      final state = await _getTableState();
      if (state.currentSize == state.desiredSize) return;

      _tableUpgradeCompleter = Completer<void>();
      isGenerating = true;

      try {
        // Logger.info("Xelis: Starting background table generation...");

        final tablesPath = await _getTablePath();
        final outputPath = '$tablesPath/${state.desiredSize.isLow ? 'low' : 'full'}';

        await x_wallet.updateTables(
          precomputedTablesPath: outputPath,
          l1Low: state.desiredSize.isLow,
        );

        // Logger.info("Xelis: Table upgrade to ${state.desiredSize.name} complete");
        _tableUpgradeCompleter?.complete();
      } catch (e, s) {
        // Logger.error("Xelis: Failed to generate tables", e, s);
        _tableUpgradeCompleter?.completeError(e);
      } finally {
        isGenerating = false;
        _tableUpgradeCompleter = null;
      }
    });
  }

  @override
  Future<XelisWallet> restoreFromHardwareWallet(
          XelisNewWalletCredentials credentials) async =>
      throw UnimplementedError();

  @override
  Future<XelisWallet> restoreFromKeys(
          XelisNewWalletCredentials credentials, {bool? isTestnet}) async =>
      throw UnimplementedError();
}
