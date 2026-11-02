import "dart:convert";
import "dart:io";

import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/imported_nft.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
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

  /// Only updates the display name (and name-keyed token rows); wallet files are
  /// stored by id and never move.
  @Deprecated(
    "Wallet files are stored by id, so renaming a wallet is display-only. "
        "Rename the wallet group instead. Kept for legacy callers; will be removed.",
  )
  Future<void> rename(WalletInfo currentWalletInfo, String password, String newName) async {
    if (currentWalletInfo.name == newName) return;

    await _renameTokenRows(currentWalletInfo.name, newName);

    currentWalletInfo.name = newName;
    await currentWalletInfo.save();
  }

  // TODO(wallet-id): tokens/NFTs are keyed by wallet name, so same-type wallets with the
  //  same name share them. Re-key by walletInfo.id, then delete this.
  Future<void> _renameTokenRows(String currentName, String newName) async {
    switch (getType()) {
      case WalletType.solana:
        await SPLToken.renameWallet(currentName, newName);
        await ImportedNFT.renameWallet(
          currentName,
          newName,
          chains: const [ImportedNFT.solanaChain],
        );
      case WalletType.tron:
        await TronToken.renameWallet(currentName, newName);
      default:
        break;
    }
  }

  Future<void> restoreWalletFilesFromBackup(WalletInfo walletInfo) async {
    final path = await walletFilePathOf(walletInfo);
    final backup = File("$path.backup");

    if (backup.existsSync()) {
      await backup.copy(path);
    }
  }

  Future<void> saveBackup(WalletInfo walletInfo) async {
    final path = await walletFilePathOf(walletInfo);
    final file = File(path);

    if (file.existsSync()) {
      await file.copy("$path.backup");
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
