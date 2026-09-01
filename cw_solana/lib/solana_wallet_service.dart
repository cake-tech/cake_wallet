import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_solana/solana_mnemonics.dart';
import 'package:cw_solana/solana_wallet.dart';
import 'package:cw_solana/solana_wallet_creation_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SolanaWalletService extends WalletService<
    SolanaNewWalletCredentials,
    SolanaRestoreWalletFromSeedCredentials,
    SolanaRestoreWalletFromPrivateKey,
    SolanaNewWalletCredentials> {
  SolanaWalletService(this.isDirect);

  final bool isDirect;

  @override
  Future<SolanaWallet> create(SolanaNewWalletCredentials credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final mnemonic = credentials.mnemonic ?? bip39.generateMnemonic(strength: strength);

    final wallet = SolanaWallet(
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      mnemonic: mnemonic,
      password: credentials.password!,
      passphrase: credentials.passphrase,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    await wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  WalletType getType() => WalletType.solana;

  @override
  Future<SolanaWallet> openWallet(WalletInfo walletInfo, String password) async {
    try {
      final wallet = await SolanaWalletBase.open(
        name: walletInfo.name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      await wallet.addInitialTokens();
      await wallet.save();
      saveBackup(walletInfo);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(walletInfo);

      final wallet = await SolanaWalletBase.open(
        name: walletInfo.name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      await wallet.addInitialTokens();
      await wallet.save();
      return wallet;
    }
  }

  @override
  Future<void> remove(WalletInfo walletInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs
        .getKeys()
        .where((k) => k.startsWith("solana_last_synced_signature_${walletInfo.name}_"))
        .toList();

    final walletName = walletInfo.name;
    await super.remove(walletInfo);

    final nameStillUsed = await WalletInfo.get(walletName, getType()) != null;
    if (!nameStillUsed) {
      await SPLToken.deleteAllForWallet(walletName);
    }

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  @override
  Future<SolanaWallet> restoreFromKeys(SolanaRestoreWalletFromPrivateKey credentials,
      {bool? isTestnet}) async {
    final wallet = SolanaWallet(
      password: credentials.password!,
      privateKey: credentials.privateKey,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    await wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<SolanaWallet> restoreFromSeed(SolanaRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw SolanaMnemonicIsIncorrectException();
    }

    final wallet = SolanaWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      passphrase: credentials.passphrase,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    await wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>>
      restoreFromHardwareWallet(SolanaNewWalletCredentials credentials) {
    // TODO: implement restoreFromHardwareWallet
    throw UnimplementedError();
  }
}
