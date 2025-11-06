import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_arbitrum/arbirtrum_mnemonics_exception.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';
import 'package:cw_evm/evm_chain_wallet_service.dart';
import 'package:cw_arbitrum/arbitrum_wallet.dart';
import 'package:cw_arbitrum/arbitrum_client.dart';

class ArbitrumWalletService extends EVMChainWalletService<ArbitrumWallet> {
  ArbitrumWalletService(super.isDirect, {required this.client});

  late ArbitrumClient client;

  @override
  WalletType getType() => WalletType.arbitrum;

  @override
  Future<ArbitrumWallet> create(EVMChainNewWalletCredentials credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final mnemonic = credentials.mnemonic ?? bip39.generateMnemonic(strength: strength);

    final wallet = ArbitrumWallet(
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
  Future<ArbitrumWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    try {
      final wallet = await ArbitrumWallet.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      wallet.addInitialTokens();
      await wallet.save();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);

      final wallet = await ArbitrumWallet.open(
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
  Future<ArbitrumWallet> restoreFromKeys(
    EVMChainRestoreWalletFromPrivateKey credentials, {
    bool? isTestnet,
  }) async {
    final wallet = ArbitrumWallet(
      password: credentials.password!,
      privateKey: credentials.privateKey,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<ArbitrumWallet> restoreFromHardwareWallet(
    EVMChainRestoreWalletFromHardware credentials,
  ) async {
    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    derivationInfo.derivationType = DerivationType.bip39;
    derivationInfo.derivationPath = "m/44'/60'/${credentials.hwAccountData.accountIndex}'/0/0";
    await derivationInfo.save();
    credentials.walletInfo!.hardwareWalletType = credentials.hardwareWalletType;
    credentials.walletInfo!.address = credentials.hwAccountData.address;
    await credentials.walletInfo!.save();

    final wallet = ArbitrumWallet(
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
  Future<ArbitrumWallet> restoreFromSeed(
    EVMChainRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw ArbitrumMnemonicIsIncorrectException();
    }

    final wallet = ArbitrumWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
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
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }
    final currentWallet = await ArbitrumWallet.open(
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

    newWalletInfo.save();
  }
}
