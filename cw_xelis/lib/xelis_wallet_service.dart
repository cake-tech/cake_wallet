import 'dart:io';
import 'dart:async';

import 'package:system_info2/system_info2.dart';

import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/utils/print_verbose.dart';

import 'package:cw_xelis/xelis_wallet.dart';
import 'package:cw_xelis/src/api/network.dart';
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;
import 'package:cw_xelis/xelis_wallet_creation_credentials.dart';
import 'package:cw_xelis/xelis_store_utils.dart';
import 'package:cw_xelis/src/api/logger.dart' as x_logger;
import 'package:cw_xelis/src/api/api.dart' as x_api;

import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

import 'package:mutex/mutex.dart';

class MemoryTierCalculator {   
  Future<int> getDeviceRAMInGB() async {
    if (kIsWeb) return 2; // Default for web

    try {
      final totalRAM = SysInfo.getTotalPhysicalMemory();
      // Convert bytes to GB (1 GB = 1024³ bytes)
      final ramGB = totalRAM / (1024 * 1024 * 1024);
      return ramGB.round();
    } catch (e) {
      print('Error getting RAM info: $e');
      return 4; // Default fallback
    }
  }
}

enum XelisTableSize {
  initial,
  web,
  low,
  medium,
  high;

  BigInt get l1Size {
    switch (this) {
      case XelisTableSize.initial:
      case XelisTableSize.web:
        return BigInt.from(23);
      case XelisTableSize.low:
        return BigInt.from(24);
      case XelisTableSize.medium:
        return BigInt.from(25);
      case XelisTableSize.high:
        return BigInt.from(26);
    }
  }

  static Future<XelisTableSize> getPlatformDefault() async {
    if (kIsWeb) {
      return XelisTableSize.web;
    }

    final calculator = MemoryTierCalculator();
    final ramInGB = await calculator.getDeviceRAMInGB();

    if (ramInGB <= 2) {
      return XelisTableSize.web;
    } else if (ramInGB <= 4) {
      return XelisTableSize.low;
    } else if (ramInGB <= 8) {
      return XelisTableSize.medium;
    } else {
      return XelisTableSize.high;
    }
  }
}


bool get kIsMobile {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}


Future<BigInt> getTableSize() async {
  final tableSize = await XelisTableSize.getPlatformDefault();
  return tableSize.l1Size;
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

  const XelisTableState({
    this.currentSize = XelisTableSize.low,
    XelisTableSize desiredSize = XelisTableSize.high,
  }) : _desiredSize = desiredSize;

  XelisTableState copyWith({
    XelisTableSize? currentSize,
    XelisTableSize? desiredSize,
  }) {
    return XelisTableState(
      currentSize: currentSize ?? this.currentSize,
      desiredSize: kIsWeb ? XelisTableSize.low : (desiredSize ?? this._desiredSize),
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
  XelisWalletService(this.walletInfoSource, {required this.isDirect}) {
    setupRustLogger();
  }
  static const LOG_LEVEL = 3;
  /*
  Log level for FFI Rust outputs in xelis_flutter

  0: None
  1: Error
  2: Warn
  3: Info
  4: Debug
  5: Trace

  */

  final Box<WalletInfo> walletInfoSource;
  final bool isDirect;

  static bool isGenerating = false;
  static final _tableUpgradeMutex = Mutex();
  static Completer<void>? _tableUpgradeCompleter;
  static XelisWallet? _activeWallet;

  void setupRustLogger() async {
    await x_api.setUpRustLogger();

    x_api.createLogStream().listen((entry) {
      final logLine = 'XELIS LOG | [${entry.level.name}] ${entry.tag}: ${entry.msg}';

      switch (entry.level) {
        case x_logger.Level.error:
          if (LOG_LEVEL > 0) {
            printV('❌ $logLine');
          }
          break;
        case x_logger.Level.warn:
          if (LOG_LEVEL > 1) {
            printV('⚠️ $logLine');
          }
          break;
        case x_logger.Level.info:
          if (LOG_LEVEL > 2) {
            printV('ℹ️ $logLine');
          }
          break;
        case x_logger.Level.debug:
          if (LOG_LEVEL > 3) {
            printV('🐛 $logLine');
          }
          break;
        case x_logger.Level.trace:
          if (LOG_LEVEL > 4) {
            printV('🔍 $logLine');
          }
          break;
      }
    },
    onError: (dynamic e) {
      printV("Error receiving Xelis Rust logs: $e");
    });
  }

  @override
  WalletType getType() => WalletType.xelis;

  @override
  Future<bool> isWalletExit(String name) async =>
      await File(await pathForWalletDir(name: name, type: getType())).exists();

  Future<void> _closeActiveWalletIfNeeded() async {
    if (_activeWallet != null) {
      try {
        await _activeWallet!.close();
      } catch (e) {
        
      }
      _activeWallet = null;
    }
  }

  Future<XelisTableState> _getTableState() async {
    final tablesPath = await _getTablePath();
    final tablesDir = Directory(tablesPath);
    final desiredSize = await XelisTableSize.getPlatformDefault();

    final files = await tablesDir.list().toList();
    
    // Check for the device-appropriate full table
    final expectedFullTableName = 'tables_${desiredSize.l1Size}.bin';

    final hasFullTables = files.any((file) => 
      file is File && file.path.contains(expectedFullTableName)
    );

    final hasLowTables = files.isNotEmpty;

    final currentSize = hasFullTables
        ? desiredSize
        : hasLowTables
            ? XelisTableSize.initial
            : XelisTableSize.initial;

    return XelisTableState(
      currentSize: currentSize,
      desiredSize: desiredSize,
    );
  }

  Future<String> _getTablePath() async {
    final root = await getAppDir();
    final prefix = walletTypeToString(getType()).toLowerCase();
    final tablesDir = Directory('${root.path}/wallets/$prefix/tables/');

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
    
    final network = isTestnet == true ? Network.testnet : Network.mainnet;

    await _closeActiveWalletIfNeeded();
    final frbWallet = await x_wallet.createXelisWallet(
      name: fullPath,
      directory: "",
      password: credentials.password ?? "x",
      network: network,
      precomputedTablesPath: tablesRoot,
      l1Size: (await _getTableState()).currentSize.l1Size,
    );

    credentials.walletInfo!.address = frbWallet.getAddressStr();
    credentials.walletInfo!.network = network.name;

    final wallet = XelisWallet(
      walletInfo:credentials.walletInfo!, 
      libWallet: frbWallet, 
      password: credentials.password ?? "x",
      network: network,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    await wallet.init();
    await wallet.save();
    unawaited(_upgradeTablesIfNeeded());
    _activeWallet = wallet;
    return wallet;
  }

  @override
  Future<XelisWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(name, getType()))!;

    final fullPath = await pathForWalletDir(name: name, type: getType());
    final tableState = await _getTableState();
    final tablesRoot = await _getTablePath();
    
    late final Network network;

    if (walletInfo?.network != null) {
      network = NetworkName.fromName(walletInfo!.network!);
    } else {
      network = await loadXelisNetwork(name);
    }

    await _closeActiveWalletIfNeeded();

    late final x_wallet.XelisWallet frbWallet;
    try {
      frbWallet = await x_wallet.openXelisWallet(
        name: fullPath,
        directory: "",
        password: password,
        network: network,
        precomputedTablesPath: tablesRoot,
        l1Size: (await _getTableState()).currentSize.l1Size,
      );
    } catch (_) {
      try {
        await restoreWalletFilesFromBackup(name);
        frbWallet = await x_wallet.openXelisWallet(
          name: fullPath,
          directory: "",
          password: password,
          network: network,
          precomputedTablesPath: tablesRoot,
          l1Size: (await _getTableState()).currentSize.l1Size,
        );
      } catch(_) {
        rethrow;
      }
    }
    final wallet = XelisWallet(
      walletInfo: walletInfo, 
      libWallet: frbWallet, 
      password: password,
      network: network,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    saveBackup(name);
    await wallet.init();
    await wallet.save();
    unawaited(_upgradeTablesIfNeeded());
    _activeWallet = wallet;
    return wallet;
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
    await saveBackup(newName);

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

    final network = isTestnet == true ? Network.testnet : Network.mainnet;

    await _closeActiveWalletIfNeeded();
    final frbWallet = await x_wallet.createXelisWallet(
      name: fullPath,
      directory: "",
      password: credentials.password ?? "x",
      seed: credentials.mnemonic,
      network: network,
      precomputedTablesPath: tablesRoot,
      l1Size: (await _getTableState()).currentSize.l1Size,
    );

    credentials.walletInfo!.address = frbWallet.getAddressStr();
    credentials.walletInfo!.network = network.name;

    final wallet = XelisWallet(
      walletInfo: credentials.walletInfo!, 
      libWallet: frbWallet, 
      password: credentials.password ?? "x",
      network: network,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    await wallet.init();
    await wallet.save();
    unawaited(_upgradeTablesIfNeeded());
    _activeWallet = wallet;
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
        printV("Xelis: Starting background table generation...");

        final tablesPath = await _getTablePath();

        await x_wallet.updateTables(
          precomputedTablesPath: tablesPath,
          l1Size: await getTableSize(),
        );

        printV("Xelis: Table upgrade to ${state.desiredSize.name} complete");
        _tableUpgradeCompleter?.complete();
      } catch (e, s) {
        printV("Xelis: Failed to generate tables, $e, $s");
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
