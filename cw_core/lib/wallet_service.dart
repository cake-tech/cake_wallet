import "dart:convert";
import "dart:io";

import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_core/utils/file.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

abstract class WalletService<N extends WalletCredentials, RFS extends WalletCredentials,
    RFK extends WalletCredentials, RFH extends WalletCredentials> {
  WalletType getType();

  Future<WalletBase> create(N credentials, {bool? isTestnet});

  Future<WalletBase> restoreFromHardwareWallet(RFH credentials);

  Future<WalletBase> restoreFromSeed(RFS credentials, {bool? isTestnet});

  Future<WalletBase> restoreFromKeys(RFK credentials, {bool? isTestnet});

  Future<WalletBase> openWallet(WalletInfo walletInfo, String password);

  Future<bool> isWalletExit(WalletInfo walletInfo) async => File(walletInfo.path).existsSync();

  Future<void> remove(WalletInfo walletInfo) async {
    final dir = Directory(walletInfo.dirPath);

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }

    await WalletInfo.delete(walletInfo);
  }

  Future<void> rename(WalletInfo currentWalletInfo, String password, String newName) async {
    if (currentWalletInfo.name == newName) {
      return;
    }

    if (!currentWalletInfo.isReady) {
      throw Exception("Wallet not found");
    }

    await _renameTokenRows(currentWalletInfo.name, newName);

    currentWalletInfo.name = newName;
    await currentWalletInfo.save();
  }

  Future<void> _renameTokenRows(String currentName, String newName) async {
    if (getType() == WalletType.solana) {
      await SPLToken.renameWallet(currentName, newName);
    }

    if (getType() == WalletType.tron) {
      await TronToken.renameWallet(currentName, newName);
    }
  }

  String _backupPathFor(WalletInfo walletInfo) => "${walletInfo.dirPath}/${walletInfo.id}.backup";

  Future<void> restoreWalletFilesFromBackup(WalletInfo walletInfo) async {
    final backupPath = _backupPathFor(walletInfo);

    if (File(backupPath).existsSync()) {
      await File(backupPath).copy(walletInfo.path);
    }
  }

  Future<void> saveBackup(WalletInfo walletInfo) async {
    final backupPath = _backupPathFor(walletInfo);

    if (File(walletInfo.path).existsSync()) {
      await File(walletInfo.path).copy(backupPath);
    }
  }


  Future<String> getSeeds(WalletInfo walletInfo, String password) async {
    try {
      final jsonSource = await read(path: walletInfo.path, password: password);
      try {
        final data = json.decode(jsonSource) as Map;
        return data["mnemonic"] as String? ?? "";
      } catch (_) {
        // if not a valid json
        return jsonSource.substring(0, 200);
      }
    } catch (_) {
      // if the file couldn't be opened or read
      return "";
    }
  }

  /// Check if the Wallet requires a hardware wallet to be connected during
  /// the opening flow. (Currently only the case for Monero)
  Future<bool> requireHardwareWalletConnection(WalletInfo walletInfo) async => false;
}
