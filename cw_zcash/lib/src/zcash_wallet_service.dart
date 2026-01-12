import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;

class ZcashWalletService
    extends
        WalletService<
          ZcashNewWalletCredentials,
          ZcashFromSeedWalletCredentials,
          ZcashFromKeysWalletCredentials,
          ZcashNewWalletCredentials
        > {
  ZcashWalletService();

  static Mutex dbMutex = Mutex();
  static int dbMutexQueue = 0;
  static Future<T> runInDbMutex<T>(final Future<T> Function() call) async {
    try {
      printV("dbMutexQueue: ${dbMutexQueue++}");
      await dbMutex.acquire();
      return await call();
    } finally {
      dbMutex.release();
      dbMutexQueue--;
    }
  }

  static Set<String> autoshieldTx = {};

  static Future<void> addShieldedTx(final String txId) async {
    final pathForWalletType = await pathForWalletTypeDir(type: type);
    final shieldedListFile = p.join(pathForWalletType, "autoshield_list.txt");
    autoshieldTx.add(txId.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ''));
    final shieldedList = File(shieldedListFile);
    shieldedList.writeAsStringSync(autoshieldTx.join("\n"));
  }

  static Future<void> loadShieldTxs() async {
    try {
      final pathForWalletType = await pathForWalletTypeDir(type: type);
      final shieldedListFile = p.join(pathForWalletType, "autoshield_list.txt");
      final shieldedList = File(shieldedListFile);
      if (!shieldedList.existsSync()) {
        return;
      }
      autoshieldTx = shieldedList.readAsLinesSync().toSet();
    } catch (e) {
      printV("loadShieldTxs failed: $e");
    }
  }

  static bool walletFilesExist(final String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => type;

  static WalletType get type => WalletType.zcash;

  @override
  Future<ZcashWallet> create(final WalletCredentials credentials, {final bool? isTestnet}) {
    return ZcashWalletBase.create(credentials);
  }

  @override
  Future<bool> isWalletExit(final String name) async {
    final path = await pathForWallet(name: name, type: getType());
    return File(path).existsSync();
  }

  @override
  Future<ZcashWallet> openWallet(final String name, final String password) async {
    await loadShieldTxs();
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    try {
      final wallet = await ZcashWalletBase.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
      );
      await wallet.init();
      await saveBackup(name);
      return wallet;
    } catch (e) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await ZcashWalletBase.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
      );
      await wallet.init();
      return wallet;
    }
  }

  @override
  Future<void> remove(final String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }

    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);
  }

  @override
  Future<void> rename(final String currentName, final String password, final String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }
    final accountId = await ZcashWalletBase.getZcashAccountIdForName(currentName);
    if (accountId == null) {
      throw Exception('Wallet account not found for name: $currentName');
    }
    final currentWallet = ZcashWallet(
      currentWalletInfo,
      await currentWalletInfo.getDerivationInfo(),
      accountId: accountId,
    );

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await newWalletInfo.save();
  }

  @override
  Future<ZcashWallet> restoreFromKeys(
    final ZcashFromKeysWalletCredentials credentials, {
    final bool? isTestnet,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ZcashWallet> restoreFromSeed(
    final ZcashFromSeedWalletCredentials credentials, {
    final bool? isTestnet,
  }) async {
    if (credentials.seed == null || credentials.seed!.isEmpty) {
      throw ZcashMnemonicIsIncorrectException();
    }

    if (!bip39.validateMnemonic(credentials.seed!)) {
      throw ZcashMnemonicIsIncorrectException();
    }

    return ZcashWalletBase.restore(credentials);
  }

  @override
  Future<ZcashWallet> restoreFromHardwareWallet(final ZcashNewWalletCredentials credentials) {
    throw UnimplementedError(
      "Restoring a Zcash wallet from a hardware wallet is not yet supported!",
    );
  }
}
