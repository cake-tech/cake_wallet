import 'dart:io';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/minotari_ffi_stub.dart';
import 'package:hive/hive.dart';

class MinotariWalletService extends WalletService<
    MinotariNewWalletCredentials,
    MinotariRestoreWalletFromSeedCredentials,
    MinotariRestoreWalletFromKeysCredentials,
    MinotariNewWalletCredentials> {
  MinotariWalletService(this.unspentCoinsInfoSource);

  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;

  @override
  WalletType getType() => WalletType.minotari;

  @override
  Future<WalletBase> create(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    final wallet = MinotariWallet(credentials.walletInfo!, derivationInfo);
    await wallet.init();

    final path = await pathForWallet(
      name: credentials.name,
      type: getType(),
    );

    final ffi = MinotariFfiStub(dataPath: path);

    // NOTE: Stubbed - actual wallet creation not implemented yet
    // This will throw an UnimplementedError with user-friendly message
    try {
      final mnemonic = _generateMnemonic();
      await ffi.createFromMnemonic(mnemonic);
    } catch (e) {
      // Re-throw the UnimplementedError to show user the message
      rethrow;
    }

    // Get and set the wallet address
    final address = await ffi.getAddress();
    wallet.walletAddresses.setAddress(address);

    await wallet.save();
    await wallet.close();

    return wallet;
  }

  @override
  Future<WalletBase> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    final derivationInfo = await walletInfo.getDerivationInfo();
    final wallet = MinotariWallet(walletInfo, derivationInfo);
    await wallet.init();

    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    final file = Directory(path);

    if (await file.exists()) {
      await file.delete(recursive: true);
    }

    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }

    final derivationInfo = await currentWalletInfo.getDerivationInfo();
    final currentWallet = MinotariWallet(currentWalletInfo, derivationInfo);

    await currentWallet.renameWalletFiles(newName);

    currentWalletInfo.name = newName;

    await currentWalletInfo.save();
  }

  @override
  Future<WalletBase> restoreFromKeys(
    MinotariRestoreWalletFromKeysCredentials credentials, {
    bool? isTestnet,
  }) async {
    // Minotari uses mnemonic-based restoration
    throw UnimplementedError('Minotari wallets use mnemonic-based restoration');
  }

  @override
  Future<WalletBase> restoreFromSeed(
    MinotariRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    final wallet = MinotariWallet(credentials.walletInfo!, derivationInfo);
    await wallet.init();

    final path = await pathForWallet(
      name: credentials.name,
      type: getType(),
    );

    final ffi = MinotariFfiStub(dataPath: path);

    // NOTE: Stubbed - actual wallet restoration not implemented yet
    try {
      await ffi.restore(credentials.mnemonic);
    } catch (e) {
      rethrow;
    }

    // Get and set the wallet address
    final address = await ffi.getAddress();
    wallet.walletAddresses.setAddress(address);

    await wallet.save();
    await wallet.close();

    return wallet;
  }

  @override
  Future<WalletBase> restoreFromHardwareWallet(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    // Minotari doesn't support hardware wallets yet
    throw UnimplementedError('Minotari hardware wallet support not yet implemented');
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

  /// Generate a 24-word BIP39 mnemonic (stubbed)
  String _generateMnemonic() {
    // Placeholder mnemonic - in real implementation, use BIP39 library
    return 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
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
