import 'dart:io';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_bitcoin/mnemonic_is_incorrect_exception.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/zpub.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:bip39/bip39.dart' as bip39;

class BitcoinWalletService extends WalletService<
    BitcoinNewWalletCredentials,
    BitcoinRestoreWalletFromSeedCredentials,
    BitcoinWalletFromKeysCredentials,
    BitcoinRestoreWalletFromHardware> {
  BitcoinWalletService(this.unspentCoinsInfoSource,
      this.payjoinSessionSource, this.isDirect);

  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  final Box<PayjoinSession> payjoinSessionSource;
  final bool isDirect;

  @override
  WalletType getType() => WalletType.bitcoin;

  @override
  Future<BitcoinWallet> create(BitcoinNewWalletCredentials credentials, {bool? isTestnet}) async {
    final network = isTestnet == true ? BitcoinNetwork.testnet : BitcoinNetwork.mainnet;
    credentials.walletInfo?.network = network.value;

    final String mnemonic;
    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    derivationInfo.derivationType = credentials.derivationInfo?.derivationType ?? derivationInfo.derivationType;
    derivationInfo.derivationPath = credentials.derivationInfo?.derivationPath ?? derivationInfo.derivationPath;
    derivationInfo.description = credentials.derivationInfo?.description ?? derivationInfo.description;
    derivationInfo.scriptType = credentials.derivationInfo?.scriptType ?? derivationInfo.scriptType;
    await derivationInfo.save();
    switch (derivationInfo.derivationType) {
      case DerivationType.bip39:
        final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

        mnemonic = credentials.mnemonic ?? await MnemonicBip39.generate(strength: strength);
        break;
      case DerivationType.electrum:
      default:
        mnemonic = await generateElectrumMnemonic();
        break;
    }
    await derivationInfo.save();

    final wallet = await BitcoinWalletBase.create(
      mnemonic: mnemonic,
      password: credentials.password!,
      passphrase: credentials.passphrase,
      walletInfo: credentials.walletInfo!,
      unspentCoinsInfo: unspentCoinsInfoSource,
      payjoinBox: payjoinSessionSource,
      network: network,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<BitcoinWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    try {
      final wallet = await BitcoinWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        payjoinBox: payjoinSessionSource,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );
      await wallet.init();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await BitcoinWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        payjoinBox: payjoinSessionSource,
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

    final unspentCoinsToDelete = unspentCoinsInfoSource.values.where(
          (unspentCoin) => unspentCoin.walletId == walletInfo.id).toList();

    final keysToDelete = unspentCoinsToDelete.map((unspentCoin) => unspentCoin.key).toList();

    if (keysToDelete.isNotEmpty) {
      await unspentCoinsInfoSource.deleteAll(keysToDelete);
    }
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }
    final currentWallet = await BitcoinWalletBase.open(
      password: password,
      name: currentName,
      walletInfo: currentWalletInfo,
      unspentCoinsInfo: unspentCoinsInfoSource,
      payjoinBox: payjoinSessionSource,
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
  Future<BitcoinWallet> restoreFromHardwareWallet(BitcoinRestoreWalletFromHardware credentials,
      {bool? isTestnet}) async {
    final network = isTestnet == true ? BitcoinNetwork.testnet : BitcoinNetwork.mainnet;
    credentials.walletInfo?.network = network.value;
    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    derivationInfo.derivationPath =
        credentials.hwAccountData.derivationPath;
    
    final xpub = convertZpubToXpub(credentials.hwAccountData.xpub!);
    
    await credentials.walletInfo!.save();
    final wallet = await BitcoinWallet(
      password: credentials.password!,
      xpub: xpub,
      walletInfo: credentials.walletInfo!,
      derivationInfo: derivationInfo,
      unspentCoinsInfo: unspentCoinsInfoSource,
      networkParam: network,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      payjoinBox: payjoinSessionSource,
    );
    await wallet.save();
    await wallet.init();
    return wallet;
  }

  @override
  Future<BitcoinWallet> restoreFromKeys(BitcoinWalletFromKeysCredentials credentials,
      {bool? isTestnet}) async {
    final network = isTestnet == true ? BitcoinNetwork.testnet : BitcoinNetwork.mainnet;
    credentials.walletInfo?.network = network.value;

    final xpub = convertZpubToXpub(credentials.xpub);

    final wallet = await BitcoinWallet(
      password: credentials.password!,
      xpub: xpub,
      walletInfo: credentials.walletInfo!,
      derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfoSource,
      networkParam: network,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      payjoinBox: payjoinSessionSource,
    );

    await wallet.save();
    await wallet.init();
    return wallet;
  }

  @override
  Future<BitcoinWallet> restoreFromSeed(BitcoinRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (!validateMnemonic(credentials.mnemonic) && !bip39.validateMnemonic(credentials.mnemonic)) {
      throw BitcoinMnemonicIsIncorrectException();
    }

    final network = isTestnet == true ? BitcoinNetwork.testnet : BitcoinNetwork.mainnet;
    credentials.walletInfo?.network = network.value;

    final wallet = await BitcoinWalletBase.create(
      password: credentials.password!,
      passphrase: credentials.passphrase,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      unspentCoinsInfo: unspentCoinsInfoSource,
      payjoinBox: payjoinSessionSource,
      network: network,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    await wallet.save();
    await wallet.init();
    return wallet;
  }
}
