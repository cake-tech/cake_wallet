import "dart:convert";
import "dart:io";

import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_keys_file.dart";
import "package:cw_core/wallet_type.dart";

abstract class WalletService<N extends WalletCredentials, RFS extends WalletCredentials,
RFK extends WalletCredentials, RFH extends WalletCredentials> {
  WalletType getType();

  Future<WalletBase> create(N credentials, {bool? isTestnet});

  Future<WalletBase> restoreFromHardwareWallet(RFH credentials);

  Future<WalletBase> restoreFromSeed(RFS credentials, {bool? isTestnet});

  Future<WalletBase> restoreFromKeys(RFK credentials, {bool? isTestnet});

  Future<WalletBase> openWallet(WalletInfo walletInfo, String password);

  Future<bool> isWalletExit(WalletInfo walletInfo) async =>
      File(await walletFilePathOf(walletInfo)).existsSync();

  Future<void> remove(WalletInfo walletInfo) async {
    final dir = Directory(await walletDirPathOf(walletInfo));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }

    await WalletInfo.delete(walletInfo);
  }

  // TODO(wallet-id): backup never ran (it checked the directory), fix separately.
  Future<void> restoreWalletFilesFromBackup(WalletInfo walletInfo) async {
    final walletDirPath = await walletDirPathOf(walletInfo);
    final backupWalletDirPath = "$walletDirPath.backup";

    if (File(backupWalletDirPath).existsSync()) {
      await File(backupWalletDirPath).copy(walletDirPath);
    }
  }

  // TODO(wallet-id): backup never ran (it checked the directory), fix separately.
  Future<void> saveBackup(WalletInfo walletInfo) async {
    final walletDirPath = await walletDirPathOf(walletInfo);
    final backupWalletDirPath = "$walletDirPath.backup";

    if (File(walletDirPath).existsSync()) {
      await File(walletDirPath).copy(backupWalletDirPath);
    }
  }

  Future<String> getSeeds(WalletInfo walletInfo, String password) async {
    try {
      final encryption = encryptionFileUtilsFor(Platform.isLinux);

      if (await WalletKeysFile.hasKeysFile(walletInfo)) {
        final keysData = await WalletKeysFile.readKeysFile(walletInfo, password, encryption);
        return keysData.mnemonic ?? keysData.altMnemonic ?? keysData.privateKey ?? "";
      }

      final path = await walletFilePathOf(walletInfo);
      if (!File(path).existsSync()) return "";

      final jsonSource = await encryption.read(path: path, password: password);
      try {
        final data = json.decode(jsonSource) as Map;
        return data["mnemonic"] as String? ?? "";
      } catch (_) {
        // Not JSON: older wallets stored the raw seed text.
        return jsonSource.length > 200 ? jsonSource.substring(0, 200) : jsonSource;
      }
    } catch (_) {
      return "";
    }
  }

  /// Whether the wallet needs a hardware wallet connected while opening.
  /// (Currently only the case for Monero.)
  Future<bool> requireHardwareWalletConnection(WalletInfo walletInfo) async => false;
}
