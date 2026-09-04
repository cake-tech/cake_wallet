import "dart:io";

import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/encryption_file_utils.dart';
import "package:cw_core/erc20_token.dart";
import "package:cw_core/imported_nft.dart";
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:cw_evm/evm_chain_client_factory.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
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

  List<WalletType> get _evmWalletTypes {
    return _registry.getRegisteredWalletTypes();
  }

  List<String> get _importedNFTChains =>
      _registry.getAllChains().map((chain) => chain.shortCode).toList();

  Future<WalletInfo?> _findWalletByName(String name) async {
    for (final type in _evmWalletTypes) {
      final walletInfo = await WalletInfo.get(name, type);
      if (walletInfo != null) {
        return walletInfo;
      }
    }
    return null;
  }
  /// getType() is not meaningful for this unified service, it throws to prevent misuse
  @override
  WalletType getType() {
    throw UnsupportedError(
      "EVMChainWalletService is unified and does not have a single type. "
      "Use walletInfo.type instead.",
    );
  }

  @override
  Future<EVMChainWallet> create(
    EVMChainNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    final walletInfo = credentials.walletInfo!;

    // Get chainId from wallet type
    final chainConfig = _registry.getChainConfigByWalletType(walletInfo.type);
    if (chainConfig == null) {
      throw Exception("Chain config not found for wallet type: ${walletInfo.type}");
    }
    final initialChainId = chainConfig.chainId;

    final client = EVMChainClientFactory.createClient(initialChainId);
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;
    final mnemonic = credentials.mnemonic ?? bip39.generateMnemonic(strength: strength);

    final derivationInfo = await walletInfo.getDerivationInfo();
    if (derivationInfo.derivationPath == null || derivationInfo.derivationPath!.isEmpty) {
      derivationInfo.derivationPath = "m/44'/60'/0'/0";
      derivationInfo.derivationType = DerivationType.bip39;
      await derivationInfo.save();
    }

    final wallet = _createWalletInstance(
      walletType: walletInfo.type,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      mnemonic: mnemonic,
      password: credentials.password!,
      passphrase: credentials.passphrase,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      initialChainId: initialChainId,
    );

    await wallet.init();
    await wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<EVMChainWallet> openWallet(WalletInfo walletInfo, String password) async {
    try {
      final wallet = await _openWalletInstance(
        name: walletInfo.name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      await wallet.addInitialTokens();
      await wallet.save();
      await saveBackup(walletInfo);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(walletInfo);

      final wallet = await _openWalletInstance(
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
  Future<void> rename(WalletInfo currentWalletInfo, String password, String newName) async {
    if (currentWalletInfo.name == newName) return;

    final oldName = currentWalletInfo.name;

    await super.rename(currentWalletInfo, password, newName);

    for (final token in await Erc20Token.selectList("walletName = ?", [oldName])) {
      final copiedToken = Erc20Token.copyWith(token, walletName: newName);
      await copiedToken.save();
    }

    final ownNFTs = (await ImportedNFT.getAllForWallet(oldName))
        .where((nft) => _importedNFTChains.contains(nft.chain));
    for (final nft in ownNFTs) {
      await ImportedNFT.copyWith(nft, walletName: newName).save();
    }
    }
  }

  @override
  Future<EVMChainWallet> restoreFromSeed(
    EVMChainRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw EVMChainMnemonicIsIncorrectException();
    }

    final walletInfo = credentials.walletInfo!;

    // Get chainId from wallet type
    final chainConfig = _registry.getChainConfigByWalletType(walletInfo.type);
    if (chainConfig == null) {
      throw Exception("Chain config not found for wallet type: ${walletInfo.type}");
    }
    final initialChainId = chainConfig.chainId;

    final client = EVMChainClientFactory.createClient(initialChainId);

    final derivationInfo = await walletInfo.getDerivationInfo();
    if (derivationInfo.derivationPath == null || derivationInfo.derivationPath!.isEmpty) {
      derivationInfo.derivationPath = "m/44'/60'/0'/0";
      derivationInfo.derivationType = DerivationType.bip39;
      await derivationInfo.save();
    }

    final wallet = _createWalletInstance(
      walletType: walletInfo.type,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      mnemonic: credentials.mnemonic,
      password: credentials.password!,
      passphrase: credentials.passphrase,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      initialChainId: initialChainId,
    );

    await wallet.init();
    await wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<EVMChainWallet> restoreFromKeys(
    EVMChainRestoreWalletFromPrivateKey credentials, {
    bool? isTestnet,
  }) async {
    final walletInfo = credentials.walletInfo!;

    // Get chainId from wallet type
    final chainConfig = _registry.getChainConfigByWalletType(walletInfo.type);
    if (chainConfig == null) {
      throw Exception("Chain config not found for wallet type: ${walletInfo.type}");
    }
    final initialChainId = chainConfig.chainId;

    final client = EVMChainClientFactory.createClient(initialChainId);

    final derivationInfo = await walletInfo.getDerivationInfo();
    if (derivationInfo.derivationPath == null || derivationInfo.derivationPath!.isEmpty) {
      derivationInfo.derivationPath = "m/44'/60'/0'/0";
      derivationInfo.derivationType = DerivationType.bip39;
      await derivationInfo.save();
    }

    final wallet = _createWalletInstance(
      walletType: walletInfo.type,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      privateKey: credentials.privateKey,
      password: credentials.password!,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      initialChainId: initialChainId,
    );

    await wallet.init();
    await wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<EVMChainWallet> restoreFromHardwareWallet(
    EVMChainRestoreWalletFromHardware credentials,
  ) async {
    final walletInfo = credentials.walletInfo!;

    // Get chainId from wallet type
    final chainConfig = _registry.getChainConfigByWalletType(walletInfo.type);
    if (chainConfig == null) {
      throw Exception("Chain config not found for wallet type: ${walletInfo.type}");
    }
    final initialChainId = chainConfig.chainId;

    final client = EVMChainClientFactory.createClient(initialChainId);
    final derivationInfo = await walletInfo.getDerivationInfo();
    derivationInfo.derivationType = DerivationType.bip39;
    derivationInfo.derivationPath = "m/44'/60'/${credentials.hwAccountData.accountIndex}'/0/0";
    await derivationInfo.save();
    walletInfo.hardwareWalletType = credentials.hardwareWalletType;
    walletInfo.address = credentials.hwAccountData.address;
    await walletInfo.save();

    final wallet = _createWalletInstance(
      walletType: walletInfo.type,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      password: credentials.password!,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      initialChainId: initialChainId,
    );

    await wallet.init();
    await wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<void> remove(WalletInfo walletInfo) async {
    await super.remove(walletInfo);
    final nameStillUsed = (await _findWalletByName(walletInfo.name)) != null;
    if (!nameStillUsed) {
      await Erc20Token.deleteAllForWallet(walletInfo.name);
      await ImportedNFT.deleteAllForWallet(walletInfo.name, chains: _importedNFTChains);
    }
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
    int? initialChainId,
  }) {
    final chainConfig = _registry.getChainConfigByWalletType(walletType);

    if (chainConfig == null) {
      throw Exception("Chain config not found for wallet type: $walletType");
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
      initialChainId: initialChainId,
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
