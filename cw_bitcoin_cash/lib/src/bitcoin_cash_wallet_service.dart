import 'dart:io';

import 'package:bip39/bip39.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_bitcoin_cash/cw_bitcoin_cash.dart';
import "package:cw_core/coin_control/coin_notes_store.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';

class BitcoinCashWalletService extends WalletService<
    BitcoinCashNewWalletCredentials,
    BitcoinCashRestoreWalletFromSeedCredentials,
    BitcoinCashRestoreWalletFromWIFCredentials,
    BitcoinCashNewWalletCredentials> {
  BitcoinCashWalletService(this.isDirect);

  final bool isDirect;

  @override
  WalletType getType() => WalletType.bitcoinCash;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<BitcoinCashWallet> create(credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final wallet = await BitcoinCashWalletBase.create(
      mnemonic: credentials.mnemonic ?? MnemonicBip39.generate(strength: strength),
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      passphrase: credentials.passphrase,
    );
    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<BitcoinCashWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    try {
      final wallet = await BitcoinCashWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await BitcoinCashWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      return wallet;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);

    await FrozenCoinsStore.instance.deleteWallet(walletInfo.id);
    await CoinNotesStore.instance.deleteWallet(walletInfo.id);
  }

  @override
  Future<BitcoinCashWallet> restoreFromHardwareWallet(BitcoinCashNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a Bitcoin Cash wallet from a hardware wallet is not yet supported!");
  }

  @override
  Future<BitcoinCashWallet> restoreFromKeys(credentials, {bool? isTestnet}) {
    // TODO: implement restoreFromKeys
    throw UnimplementedError('restoreFromKeys() is not implemented');
  }

  @override
  Future<BitcoinCashWallet> restoreFromSeed(BitcoinCashRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw BitcoinCashMnemonicIsIncorrectException();
    }

    final wallet = await BitcoinCashWalletBase.create(
        password: credentials.password!,
        mnemonic: credentials.mnemonic,
        walletInfo: credentials.walletInfo!,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
        passphrase: credentials.passphrase);
    await wallet.save();
    await wallet.init();
    return wallet;
  }
}
