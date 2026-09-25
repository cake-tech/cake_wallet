import 'dart:io';

import 'package:bip39/bip39.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_pivx/cw_pivx.dart';
import 'package:cw_pivx/src/sapling/sapling_note_storage.dart';
import 'package:hive/hive.dart';

class PivxWalletService extends WalletService<
    PivxNewWalletCredentials,
    PivxRestoreWalletFromSeedCredentials,
    PivxRestoreWalletFromWIFCredentials,
    PivxNewWalletCredentials> {
  PivxWalletService(this.unspentCoinsInfoSource, this.isDirect);

  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  final bool isDirect;

  @override
  WalletType getType() => WalletType.pivx;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<PivxWallet> create(credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;
    credentials.walletInfo!.network = 'mainnet';
    // A reused seed (wallet groups) can already hold notes: scan from Sapling
    // activation instead of estimating a birthday from the creation time.
    if (credentials.mnemonic != null) credentials.walletInfo!.isRecovery = true;
    await _deleteNoteFile(credentials.walletInfo!.id);

    final wallet = await PivxWalletBase.create(
      mnemonic:
          credentials.mnemonic ?? MnemonicBip39.generate(strength: strength),
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      passphrase: credentials.passphrase,
    );
    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<PivxWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    try {
      final wallet = await PivxWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await PivxWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      return wallet;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    // The note file's id derives from the name, so it goes first, before any
    // step below can throw and leave it on disk.
    await _deleteNoteFile(WalletBase.idFor(wallet, getType()));
    await Directory(await pathForWalletDir(name: wallet, type: getType()))
        .delete(recursive: true);
    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);

    final unspentCoinsToDelete = unspentCoinsInfoSource.values
        .where((unspentCoin) => unspentCoin.walletId == walletInfo.id)
        .toList();

    final keysToDelete =
        unspentCoinsToDelete.map((unspentCoin) => unspentCoin.key).toList();

    if (keysToDelete.isNotEmpty) {
      await unspentCoinsInfoSource.deleteAll(keysToDelete);
    }
  }

  // Shared rename copies files, saves metadata and deletes the old dir; the
  // Sapling note file lives outside the wallet dir and moves separately.
  @override
  Future<void> rename(
      String currentName, String password, String newName) async {
    if (currentName == newName) return;
    final oldId = WalletBase.idFor(currentName, getType());
    final newId = WalletBase.idFor(newName, getType());
    await SaplingNoteStorage.rename(oldId, newId);
    try {
      await super.rename(currentName, password, newName);
    } catch (_) {
      // Metadata still says oldId; put the note file back where it looks.
      await SaplingNoteStorage.rename(newId, oldId);
      rethrow;
    }
  }

  @override
  Future<PivxWallet> restoreFromHardwareWallet(
      PivxNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a PIVX wallet from a hardware wallet is not yet supported!");
  }

  @override
  Future<PivxWallet> restoreFromKeys(
      PivxRestoreWalletFromWIFCredentials credentials,
      {bool? isTestnet}) {
    throw UnimplementedError(
        "PIVX wallets restore from a seed phrase; WIF key import is not supported!");
  }

  @override
  Future<PivxWallet> restoreFromSeed(
    PivxRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw Exception('Invalid PIVX mnemonic');
    }
    credentials.walletInfo!.network = 'mainnet';
    await _deleteNoteFile(credentials.walletInfo!.id);

    final wallet = await PivxWalletBase.create(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      passphrase: credentials.passphrase,
    );
    await wallet.save();
    await wallet.init();
    return wallet;
  }

  // Encrypted with that wallet's password; a later wallet reusing the id
  // cannot read it and shield sync fails for good.
  Future<void> _deleteNoteFile(String walletId) async {
    final file = File(await SaplingNoteStorage.pathFor(walletId));
    if (await file.exists()) await file.delete();
  }
}
