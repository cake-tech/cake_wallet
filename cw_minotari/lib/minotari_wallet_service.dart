import 'dart:io';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/minotari_ffi.dart';
import 'package:hive/hive.dart';

class MinotariWalletService extends WalletService<
    MinotariNewWalletCredentials,
    MinotariRestoreWalletFromSeedCredentials,
    MinotariRestoreWalletFromKeysCredentials,
    MinotariNewWalletCredentials> {
  MinotariWalletService(this.walletInfoSource, this.unspentCoinsInfoSource);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;

  @override
  WalletType getType() => WalletType.minotari;

  @override
  Future<MinotariWallet> create(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    final wallet = MinotariWallet(credentials.walletInfo!);
    await wallet.init();

    final path = await pathForWallet(
      name: credentials.name,
      type: getType(),
    );

    final ffi = MinotariFfi(dataPath: path);

    // Generate new mnemonic and create wallet
    // TODO: Generate mnemonic using BIP39
    final mnemonic = _generateMnemonic();
    await ffi.createFromMnemonic(mnemonic);

    // Get and set the wallet address
    final address = await ffi.getAddress();
    wallet.walletAddresses.setAddress(address);

    await wallet.save();
    await wallet.close();

    return wallet;
  }

  @override
  Future<MinotariWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(name, getType()));

    final wallet = MinotariWallet(walletInfo);
    await wallet.init();

    // Get and set the wallet address
    final address = await wallet._ffi?.getAddress();
    if (address != null) {
      wallet.walletAddresses.setAddress(address);
    }

    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    final file = Directory(path);

    if (await file.exists()) {
      await file.delete(recursive: true);
    }

    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(wallet, getType()));
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values.firstWhere(
      (info) => info.id == WalletBase.idFor(currentName, getType()),
    );

    final currentWallet = MinotariWallet(currentWalletInfo);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<MinotariWallet> restoreFromKeys(
    MinotariRestoreWalletFromKeysCredentials credentials, {
    bool? isTestnet,
  }) async {
    // Minotari uses mnemonic-based restoration
    throw UnimplementedError('Minotari wallets use mnemonic-based restoration');
  }

  @override
  Future<MinotariWallet> restoreFromSeed(
    MinotariRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    final wallet = MinotariWallet(credentials.walletInfo!);
    await wallet.init();

    final path = await pathForWallet(
      name: credentials.name,
      type: getType(),
    );

    final ffi = MinotariFfi(dataPath: path);
    await ffi.restore(credentials.mnemonic);

    // Get and set the wallet address
    final address = await ffi.getAddress();
    wallet.walletAddresses.setAddress(address);

    await wallet.save();
    await wallet.close();

    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name, type: getType());
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Generate a 24-word BIP39 mnemonic
  String _generateMnemonic() {
    // TODO: Implement proper BIP39 mnemonic generation
    // This is a placeholder
    throw UnimplementedError('Mnemonic generation not yet implemented');
  }
}

class MinotariNewWalletCredentials extends WalletCredentials {
  MinotariNewWalletCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class MinotariRestoreWalletFromSeedCredentials extends WalletCredentials {
  MinotariRestoreWalletFromSeedCredentials({
    required String name,
    required this.mnemonic,
    required int height,
    WalletInfo? walletInfo,
  }) : super(name: name, height: height, walletInfo: walletInfo);

  final String mnemonic;
}

class MinotariRestoreWalletFromKeysCredentials extends WalletCredentials {
  MinotariRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required this.language,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, walletInfo: walletInfo);

  final String language;
}
