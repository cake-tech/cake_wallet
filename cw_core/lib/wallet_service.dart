import 'dart:convert';
import 'dart:io';

import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_type.dart';

abstract class WalletService<N extends WalletCredentials, RFS extends WalletCredentials,
    RFK extends WalletCredentials, RFH extends WalletCredentials> {
  WalletType getType();

  Future<WalletBase> create(N credentials, {bool? isTestnet});

  Future<WalletBase> restoreFromHardwareWallet(RFH credentials);

  Future<WalletBase> restoreFromSeed(RFS credentials, {bool? isTestnet});

  Future<WalletBase> restoreFromKeys(RFK credentials, {bool? isTestnet});

  Future<WalletBase> openWallet(String name, String password);

  Future<bool> isWalletExit(String name);

  Future<void> remove(String wallet);

  Future<void> rename(String currentName, String password, String newName);

  Future<void> restoreWalletFilesFromBackup(String name) async {
    final backupWalletDirPath = await pathForWalletDir(name: "$name.backup", type: getType());
    final walletDirPath = await pathForWalletDir(name: name, type: getType());

    if (File(backupWalletDirPath).existsSync()) {
      await File(backupWalletDirPath).copy(walletDirPath);
    }
  }

  Future<void> saveBackup(String name) async {
    final backupWalletDirPath = await pathForWalletDir(name: "$name.backup", type: getType());
    final walletDirPath = await pathForWalletDir(name: name, type: getType());

    if (File(walletDirPath).existsSync()) {
      await File(walletDirPath).copy(backupWalletDirPath);
    }
  }

  Future<String> getSeeds(String name, String password, WalletType type) async {
    try {
      final path = await pathForWallet(name: name, type: type);
      final jsonSource = await read(path: path, password: password);
      try {
        final data = json.decode(jsonSource) as Map;
        return data['mnemonic'] as String? ?? '';
      } catch (_) {
        // if not a valid json
        return jsonSource.substring(0, 200);
      }
    } catch (_) {
      // if the file couldn't be opened or read
      return '';
    }
  }

  /// Check if the Wallet requires a hardware wallet to be connected during
  /// the opening flow. (Currently only the case for Monero)
  bool requireHardwareWalletConnection(String name) => false;
}
