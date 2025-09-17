import 'dart:io';

import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_nano/nano_mnemonic.dart' as nm;
import 'package:cw_nano/nano_wallet.dart';
import 'package:cw_nano/nano_wallet_creation_credentials.dart';
import 'package:hive/hive.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:nanodart/nanodart.dart';
import 'package:nanoutil/nanoutil.dart';

class NanoWalletService extends WalletService<
    NanoNewWalletCredentials,
    NanoRestoreWalletFromSeedCredentials,
    NanoRestoreWalletFromKeysCredentials,
    NanoNewWalletCredentials> {
  NanoWalletService(this.isDirect);

  final bool isDirect;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.nano;

  @override
  Future<WalletBase> create(NanoNewWalletCredentials credentials, {bool? isTestnet}) async {
    final String mnemonic;
    final derivationInfo = credentials.derivationInfo ?? await credentials.walletInfo!.getDerivationInfo();
    switch (derivationInfo.derivationType) {
      case DerivationType.nano:
        String seedKey = NanoSeeds.generateSeed();
        mnemonic = credentials.mnemonic ?? NanoDerivations.standardSeedToMnemonic(seedKey);
        break;
      case DerivationType.bip39:
      default:
        final strength = credentials.seedPhraseLength == 24 ? 256 : 128;
        mnemonic = credentials.mnemonic ?? bip39.generateMnemonic(strength: strength);
        break;
    }

    final wallet = NanoWallet(
      walletInfo: credentials.walletInfo!,
      derivationInfo: derivationInfo,
      mnemonic: mnemonic,
      password: credentials.password!,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    await wallet.init();
    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }

    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }

    String randomWords =
        (List<String>.from(nm.NanoMnemomics.WORDLIST)..shuffle()).take(24).join(' ');
    final currentWallet = NanoWallet(
      walletInfo: currentWalletInfo,
      derivationInfo: await currentWalletInfo.getDerivationInfo(),
      password: password,
      mnemonic: randomWords,
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
  Future<NanoWallet> restoreFromKeys(NanoRestoreWalletFromKeysCredentials credentials,
      {bool? isTestnet}) async {
    if (credentials.seedKey.contains(' ')) {
      throw Exception("Invalid key!");
    } else {
      if (credentials.seedKey.length != 64 && credentials.seedKey.length != 128) {
        throw Exception("Invalid key length!");
      }
    }

    String? mnemonic;

    // we can't derive the mnemonic from the key in all cases, only if it's a "nano" seed
    if (credentials.seedKey.length == 64) {
      try {
        mnemonic = NanoDerivations.standardSeedToMnemonic(credentials.seedKey);
      } catch (e) {
        throw Exception("Wasn't a valid nano style seed!");
      }
    }
    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    // should never happen but just in case:
    if (derivationInfo.derivationType == null) {
      derivationInfo.derivationType = DerivationType.nano;
    }

    final wallet = await NanoWallet(
      password: credentials.password!,
      mnemonic: mnemonic ?? credentials.seedKey,
      walletInfo: credentials.walletInfo!,
      derivationInfo: derivationInfo,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );
    await wallet.init();
    await wallet.save();
    return wallet;
  }

  @override
  Future<NanoWallet> restoreFromHardwareWallet(NanoNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a Nano wallet from a hardware wallet is not yet supported!");
  }

  @override
  Future<NanoWallet> restoreFromSeed(NanoRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (credentials.mnemonic.contains(' ')) {
      if (!bip39.validateMnemonic(credentials.mnemonic)) {
        throw nm.NanoMnemonicIsIncorrectException();
      }

      if (!NanoMnemomics.validateMnemonic(credentials.mnemonic.split(' '))) {
        throw nm.NanoMnemonicIsIncorrectException();
      }
    } else {
      if (credentials.mnemonic.length != 64 && credentials.mnemonic.length != 128) {
        throw Exception("Invalid seed length");
      }
    }

    final derivationInfo = await credentials.walletInfo!.getDerivationInfo();
    DerivationType derivationType = derivationInfo.derivationType ?? DerivationType.nano;

    derivationInfo.derivationType = derivationType;
    derivationInfo.save();

    final wallet = await NanoWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      derivationInfo: derivationInfo,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    await wallet.save();
    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<NanoWallet> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    try {
      final wallet = await NanoWalletBase.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      await wallet.save();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);
      final wallet = await NanoWalletBase.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      await wallet.save();
      return wallet;
    }
  }
}
