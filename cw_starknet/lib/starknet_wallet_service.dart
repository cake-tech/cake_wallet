import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_starknet/starknet_client.dart';
import 'package:cw_starknet/starknet_exceptions.dart';
import 'package:cw_starknet/starknet_mnemonics.dart';
import 'package:cw_starknet/starknet_wallet.dart';
import 'package:cw_starknet/starknet_wallet_creation_credentials.dart';

class StarknetWalletService extends WalletService<
    StarknetNewWalletCredentials,
    StarknetRestoreWalletFromSeedCredentials,
    StarknetRestoreWalletFromPrivateKey,
    StarknetRestoreWalletFromHardware> {
  StarknetWalletService(this.isDirect, {StarknetWalletClient Function()? clientFactory})
      : _clientFactory = clientFactory;

  final bool isDirect;
  final StarknetWalletClient Function()? _clientFactory;

  @override
  Future<StarknetWallet> create(StarknetNewWalletCredentials credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final mnemonic = credentials.mnemonic ?? bip39.generateMnemonic(strength: strength);

    final wallet = StarknetWallet(
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      mnemonic: mnemonic,
      password: credentials.password!,
      passphrase: credentials.passphrase,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      client: _clientFactory?.call(),
    );

    await wallet.init();
    await wallet.save();
    return wallet;
  }

  @override
  WalletType getType() => WalletType.starknet;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<StarknetWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw StarknetTransactionCreationException.fromMessage('Wallet "$name" not found');
    }

    try {
      final wallet = await _openAndInit(name, password, walletInfo);
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);
      return _openAndInit(name, password, walletInfo);
    }
  }

  Future<StarknetWallet> _openAndInit(String name, String password, WalletInfo walletInfo) async {
    final wallet = await StarknetWalletBase.open(
      name: name,
      password: password,
      walletInfo: walletInfo,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    await wallet.init();
    await wallet.save();
    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw StarknetTransactionCreationException.fromMessage('Wallet "$wallet" not found');
    }
    await WalletInfo.delete(walletInfo);
  }

  @override
  Future<StarknetWallet> restoreFromKeys(StarknetRestoreWalletFromPrivateKey credentials,
      {bool? isTestnet}) async {
    if (credentials.publicKey != null && credentials.privateKey == null) {
      final wallet = StarknetWallet(
        password: credentials.password!,
        walletInfo: credentials.walletInfo!,
        derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
        hardwarePublicKeyHex: credentials.publicKey,
        accountClassHashHex: credentials.accountClassHashHex,
        client: _clientFactory?.call(),
      );

      await wallet.init();
      await wallet.save();

      return wallet;
    }

    final wallet = StarknetWallet(
      password: credentials.password!,
      privateKey: credentials.privateKey,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      client: _clientFactory?.call(),
    );

    await wallet.init();
    await wallet.save();

    return wallet;
  }

  @override
  Future<StarknetWallet> restoreFromSeed(StarknetRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw StarknetMnemonicIsIncorrectException();
    }

    final wallet = StarknetWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      passphrase: credentials.passphrase,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      client: _clientFactory?.call(),
    );

    await wallet.init();
    await wallet.save();

    return wallet;
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw StarknetTransactionCreationException.fromMessage('Wallet "$currentName" not found');
    }
    final currentWallet = await StarknetWalletBase.open(
      password: password,
      name: currentName,
      walletInfo: currentWalletInfo,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await newWalletInfo.save();
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>>
      restoreFromHardwareWallet(StarknetRestoreWalletFromHardware credentials) async {
    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    derivationInfo.derivationType = DerivationType.bip39;
    derivationInfo.derivationPath = credentials.hwAccountData.derivationPath;
    await derivationInfo.save();

    final walletInfo = credentials.walletInfo!;
    walletInfo.hardwareWalletType = credentials.hardwareWalletType;
    walletInfo.address = credentials.hwAccountData.address;
    await walletInfo.save();

    final wallet = StarknetWallet(
      password: credentials.password!,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      hardwarePublicKeyHex: credentials.hwAccountData.publicKey,
      hardwareDerivationPath: credentials.hwAccountData.derivationPath,
      accountClassHashHex: credentials.accountClassHashHex,
      client: _clientFactory?.call(),
    );

    await wallet.init();
    await wallet.save();

    return wallet;
  }
}
