import 'dart:io';
import 'dart:typed_data';
import 'package:cw_digibyte/digibyte_network.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_bitcoin/litecoin_wallet.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'digibyte_mnemonic_is_incorrect_exception.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

import 'digibyte_wallet.dart';

class DigibyteWalletService extends WalletService<
    BitcoinNewWalletCredentials,
    BitcoinRestoreWalletFromSeedCredentials,
    BitcoinRestoreWalletFromWIFCredentials,
    BitcoinRestoreWalletFromHardware> {
  DigibyteWalletService(
      this.walletInfoSource, this.unspentCoinsInfoSource, this.alwaysScan, this.isDirect);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  final bool alwaysScan;
  final bool isDirect;

  @override
  WalletType getType() => WalletType.digibyte;

  @override
  Future<DigibyteWallet> create(BitcoinNewWalletCredentials credentials, {bool? isTestnet}) async {
    final String mnemonic;
    switch (credentials.walletInfo?.derivationInfo?.derivationType) {
      case DerivationType.bip39:
        final strength = credentials.seedPhraseLength == 24 ? 256 : 128;
        mnemonic = credentials.mnemonic ?? await MnemonicBip39.generate(strength: strength);
        break;
      case DerivationType.electrum:
      default:
        mnemonic = await generateElectrumMnemonic();
        break;
    }

    final wallet = await DigibyteWalletBase.create(
      mnemonic: mnemonic,
      password: credentials.password!,
      passphrase: credentials.passphrase,
      walletInfo: credentials.walletInfo!,
      unspentCoinsInfo: unspentCoinsInfoSource,
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
  Future<DigibyteWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(name, getType()))!;

    try {
      final wallet = await DigibyteWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        alwaysScan: alwaysScan,
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
        alwaysScan: alwaysScan,
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
      alwaysScan: alwaysScan,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<DigibyteWallet> restoreFromHardwareWallet(
    BitcoinRestoreWalletFromHardware credentials, {
    bool? isTestnet,
  }) async {
    final network = isTestnet == true ? DigibyteNetwork.testnet : DigibyteNetwork.mainnet;
    credentials.walletInfo?.network = network.value;
    credentials.walletInfo?.derivationInfo?.derivationPath = credentials.hwAccountData.derivationPath;

    final wallet = await DigibyteWallet(
      password: credentials.password!,
      xpub: credentials.hwAccountData.xpub,
      walletInfo: credentials.walletInfo!,
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    await wallet.save();
    await wallet.init();
    return wallet;
  }

  @override
  Future<DigibyteWallet> restoreFromKeys(
      BitcoinRestoreWalletFromWIFCredentials credentials,
      {bool? isTestnet}) async {
    final network =
        isTestnet == true ? DigibyteNetwork.testnet : DigibyteNetwork.mainnet;

    credentials.walletInfo?.network = network.value;
    credentials.walletInfo?.derivationInfo ??= DerivationInfo(
      derivationType: DerivationType.electrum,
      derivationPath: electrum_path,
    );

    final ecPrivate =
        ECPrivate.fromWif(credentials.wif, netVersion: network.wifNetVer);

    final wallet = DigibyteWallet(
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      seedBytes: Uint8List.fromList(ecPrivate.toBytes()),
    );

    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<DigibyteWallet> restoreFromSeed(BitcoinRestoreWalletFromSeedCredentials credentials, {bool? isTestnet}) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw DigibyteMnemonicIsIncorrectException();
    }

    final wallet = await DigibyteWalletBase.create(
      password: credentials.password!,
      passphrase: credentials.passphrase,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      unspentCoinsInfo: unspentCoinsInfoSource,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    await wallet.save();
    await wallet.init();
    return wallet;
  }
}
