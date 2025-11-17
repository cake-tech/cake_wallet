import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:cw_evm/evm_chain_client_factory.dart';
import 'package:cw_evm/evm_chain_registry.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';

/// Unified service for all EVM chains (Ethereum, Polygon, Base, Arbitrum, etc.)
///
/// This service dynamically determines which chain to use based on WalletType
/// from credentials or walletInfo, eliminating the need for separate service
/// classes per chain.
class EVMChainWalletService extends WalletService<
    EVMChainNewWalletCredentials,
    EVMChainRestoreWalletFromSeedCredentials,
    EVMChainRestoreWalletFromPrivateKey,
    EVMChainRestoreWalletFromHardware> {
  EVMChainWalletService(this.isDirect);

  final bool isDirect;
  final EvmChainRegistry _registry = EvmChainRegistry();

  List<WalletType> get _evmWalletTypes => _registry.getRegisteredWalletTypes();

  Future<WalletInfo?> _findWalletByName(String name) async {
    for (final type in _evmWalletTypes) {
      final walletInfo = await WalletInfo.get(name, type);
      if (walletInfo != null) {
        return walletInfo;
      }
    }
    return null;
  }

  WalletType _getWalletType(WalletInfo? walletInfo) {
    if (walletInfo?.type == null) {
      throw Exception('Wallet type not specified');
    }

    if (!_evmWalletTypes.contains(walletInfo!.type)) {
      throw Exception('Unsupported wallet type: ${walletInfo.type}');
    }

    return walletInfo.type;
  }

  /// getType() is not meaningful for this unified service, it throws to prevent misuse
  @override
  WalletType getType() {
    throw UnsupportedError(
      'EVMChainWalletService is unified and does not have a single type. '
      'Use walletInfo.type instead.',
    );
  }

  /// Override saveBackup to look up walletType from wallet name
  @override
  Future<void> saveBackup(String name) async {
    final walletInfo = await _findWalletByName(name);
    if (walletInfo == null) {
      throw Exception('Wallet not found: $name');
    }

    final backupWalletDirPath = await pathForWalletDir(name: "$name.backup", type: walletInfo.type);
    final walletDirPath = await pathForWalletDir(name: name, type: walletInfo.type);

    if (File(walletDirPath).existsSync()) {
      await File(walletDirPath).copy(backupWalletDirPath);
    }
  }

  /// Override restoreWalletFilesFromBackup to look up walletType from wallet name
  @override
  Future<void> restoreWalletFilesFromBackup(String name) async {
    final walletInfo = await _findWalletByName(name);
    if (walletInfo == null) {
      throw Exception('Wallet not found: $name');
    }

    final backupWalletDirPath = await pathForWalletDir(name: "$name.backup", type: walletInfo.type);
    final walletDirPath = await pathForWalletDir(name: name, type: walletInfo.type);

    if (File(backupWalletDirPath).existsSync()) {
      await File(backupWalletDirPath).copy(walletDirPath);
    }
  }

  @override
  Future<EVMChainWallet> create(
    EVMChainNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    final walletType = _getWalletType(credentials.walletInfo);
    final chainConfig = _registry.getChainConfigByWalletType(walletType);

    if (chainConfig == null) {
      throw Exception('Chain config not found for wallet type: $walletType');
    }

    final client = EVMChainClientFactory.createClient(chainConfig.chainId);
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;
    final mnemonic = credentials.mnemonic ?? bip39.generateMnemonic(strength: strength);

    final wallet = _createWalletInstance(
      walletType: walletType,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      mnemonic: mnemonic,
      password: credentials.password!,
      passphrase: credentials.passphrase,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<EVMChainWallet> openWallet(String name, String password) async {
    final walletInfo = await _findWalletByName(name);
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    final walletType = walletInfo.type;
    final chainConfig = _registry.getChainConfigByWalletType(walletType);
    if (chainConfig == null) {
      throw Exception('Chain config not found for wallet type: $walletType');
    }

    try {
      final wallet = await _openWalletInstance(
        name: name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      wallet.addInitialTokens();
      await wallet.save();
      await saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);

      final wallet = await _openWalletInstance(
        name: name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      wallet.addInitialTokens();
      await wallet.save();
      return wallet;
    }
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await _findWalletByName(currentName);
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }

    final currentWallet = await _openWalletInstance(
      password: password,
      name: currentName,
      walletInfo: currentWalletInfo,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, currentWalletInfo.type);
    newWalletInfo.name = newName;

    await newWalletInfo.save();
  }

  @override
  Future<EVMChainWallet> restoreFromSeed(
    EVMChainRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    final walletType = _getWalletType(credentials.walletInfo);
    final chainConfig = _registry.getChainConfigByWalletType(walletType);

    if (chainConfig == null) {
      throw Exception('Chain config not found for wallet type: $walletType');
    }

    final client = EVMChainClientFactory.createClient(chainConfig.chainId);

    final wallet = _createWalletInstance(
      walletType: walletType,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      mnemonic: credentials.mnemonic,
      password: credentials.password!,
      passphrase: credentials.passphrase,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<EVMChainWallet> restoreFromKeys(
    EVMChainRestoreWalletFromPrivateKey credentials, {
    bool? isTestnet,
  }) async {
    final walletType = _getWalletType(credentials.walletInfo);
    final chainConfig = _registry.getChainConfigByWalletType(walletType);
    if (chainConfig == null) {
      throw Exception('Chain config not found for wallet type: $walletType');
    }

    final client = EVMChainClientFactory.createClient(chainConfig.chainId);

    final wallet = _createWalletInstance(
      walletType: walletType,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      privateKey: credentials.privateKey,
      password: credentials.password!,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<EVMChainWallet> restoreFromHardwareWallet(
    EVMChainRestoreWalletFromHardware credentials,
  ) async {
    final walletType = _getWalletType(credentials.walletInfo);
    final chainConfig = _registry.getChainConfigByWalletType(walletType);
    if (chainConfig == null) {
      throw Exception('Chain config not found for wallet type: $walletType');
    }

    final client = EVMChainClientFactory.createClient(chainConfig.chainId);
    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    derivationInfo.derivationType = DerivationType.bip39;
    derivationInfo.derivationPath = "m/44'/60'/${credentials.hwAccountData.accountIndex}'/0/0";
    await derivationInfo.save();
    credentials.walletInfo!.hardwareWalletType = credentials.hardwareWalletType;
    credentials.walletInfo!.address = credentials.hwAccountData.address;
    await credentials.walletInfo!.save();

    final wallet = _createWalletInstance(
      walletType: walletType,
      walletInfo: credentials.walletInfo!,
      derivationInfo: derivationInfo,
      password: credentials.password!,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async {
    for (final type in _evmWalletTypes) {
      if (File(await pathForWallet(name: name, type: type)).existsSync()) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> remove(String wallet) async {
    final walletInfo = await _findWalletByName(wallet);
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    File(await pathForWalletDir(name: wallet, type: walletInfo.type)).delete(recursive: true);
    await WalletInfo.delete(walletInfo);
  }

  EVMChainWallet _createWalletInstance({
    required WalletType walletType,
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    String? mnemonic,
    String? privateKey,
    required String password,
    required EVMChainClient client,
    required EncryptionFileUtils encryptionFileUtils,
    String? passphrase,
  }) {
    final chainConfig = _registry.getChainConfigByWalletType(walletType);

    if (chainConfig == null) {
      throw Exception('Chain config not found for wallet type: $walletType');
    }

    return EVMChainWallet(
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      mnemonic: mnemonic,
      privateKey: privateKey,
      password: password,
      passphrase: passphrase,
      client: client,
      nativeCurrency: chainConfig.nativeCurrency,
      encryptionFileUtils: encryptionFileUtils,
    );
  }

  Future<EVMChainWallet> _openWalletInstance({
    required String name,
    required String password,
    required WalletInfo walletInfo,
    required EncryptionFileUtils encryptionFileUtils,
  }) {
    return EVMChainWalletBase.open(
      name: name,
      password: password,
      walletInfo: walletInfo,
      encryptionFileUtils: encryptionFileUtils,
    );
  }
}
