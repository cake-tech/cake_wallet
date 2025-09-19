import 'dart:io';

import 'package:bip39/bip39.dart';
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_digibyte/cw_digibyte.dart';
import 'package:hive/hive.dart';

class DigibyteWalletService extends WalletService<
    DigibyteNewWalletCredentials,
    DigibyteRestoreWalletFromSeedCredentials,
    DigibyteRestoreWalletFromWIFCredentials,
    DigibyteNewWalletCredentials> {
  DigibyteWalletService(this.walletInfoSource, this.unspentCoinsInfoSource, this.isDirect);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  final bool isDirect;
  static const _defaultDerivationPath = "m/44'/20'/0'";

  void _ensureDefaultDerivation(WalletInfo info) {
    info.derivationInfo ??= DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: _defaultDerivationPath,
    );
  }

  @override
  WalletType getType() => WalletType.digibyte;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<DigibyteWallet> create(credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    _ensureDefaultDerivation(credentials.walletInfo!);

    final wallet = await DigibyteWalletBase.create(
      mnemonic: credentials.mnemonic ?? MnemonicBip39.generate(strength: strength),
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      passphrase: credentials.passphrase,
    );
    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<DigibyteWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(name, getType()))!;

    try {
      final wallet = await DigibyteWalletBase.open(
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
      final wallet = await DigibyteWalletBase.open(
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
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(wallet, getType()))!;
    await walletInfoSource.delete(walletInfo.key);

    final unspentCoinsToDelete = unspentCoinsInfoSource.values
        .where((unspentCoin) => unspentCoin.walletId == walletInfo.id)
        .toList();

    final keysToDelete = unspentCoinsToDelete.map((unspentCoin) => unspentCoin.key).toList();

    if (keysToDelete.isNotEmpty) {
      await unspentCoinsInfoSource.deleteAll(keysToDelete);
    }
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(currentName, getType()))!;
    final currentWallet = await DigibyteWalletBase.open(
        password: password,
        name: currentName,
        walletInfo: currentWalletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect));

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<DigibyteWallet> restoreFromHardwareWallet(DigibyteNewWalletCredentials credentials) {
    throw UnimplementedError(
        'Restoring a DigiByte wallet from a hardware wallet is not yet supported!');
  }

  @override
  Future<DigibyteWallet> restoreFromKeys(credentials, {bool? isTestnet}) async {
    try {
      _ensureDefaultDerivation(credentials.walletInfo!);

      final wallet = await DigibyteWalletBase.restoreFromWIF(
        wif: credentials.wif,
        password: credentials.password!,
        walletInfo: credentials.walletInfo!,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.save();
      await wallet.init();

      return wallet;
    } catch (e) {
      throw Exception('Failed to restore DigiByte wallet from WIF: $e');
    }
  }

  @override
  Future<DigibyteWallet> restoreFromSeed(DigibyteRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw Exception('Invalid mnemonic: ${credentials.mnemonic}');
    }

    _ensureDefaultDerivation(credentials.walletInfo!);

    final wallet = await DigibyteWalletBase.create(
        password: credentials.password!,
        mnemonic: credentials.mnemonic,
        walletInfo: credentials.walletInfo!,
        unspentCoinsInfo: unspentCoinsInfoSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
        passphrase: credentials.passphrase);
    await wallet.save();
    await wallet.init();
    return wallet;
  }
}
