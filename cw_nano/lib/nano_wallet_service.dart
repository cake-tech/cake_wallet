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
  NanoWalletService(this.walletInfoSource, this.isDirect);

  final Box<WalletInfo> walletInfoSource;
  final bool isDirect;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.nano;

  @override
  Future<WalletBase> create(NanoNewWalletCredentials credentials, {bool? isTestnet}) async {
    // nano standard:
    String seedKey = NanoSeeds.generateSeed();
    String mnemonic = NanoDerivations.standardSeedToMnemonic(seedKey);

    // should never happen but just in case:
    if (credentials.walletInfo!.derivationInfo == null) {
      credentials.walletInfo!.derivationInfo = DerivationInfo(derivationType: DerivationType.nano);
    } else if (credentials.walletInfo!.derivationInfo!.derivationType == null) {
      credentials.walletInfo!.derivationInfo!.derivationType = DerivationType.nano;
    }

    final wallet = NanoWallet(
      walletInfo: credentials.walletInfo!,
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

    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(wallet, getType()));
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));

    String randomWords =
        (List<String>.from(nm.NanoMnemomics.WORDLIST)..shuffle()).take(24).join(' ');
    final currentWallet = NanoWallet(
      walletInfo: currentWalletInfo,
      password: password,
      mnemonic: randomWords,
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

    // should never happen but just in case:
    if (credentials.walletInfo!.derivationInfo == null) {
      credentials.walletInfo!.derivationInfo = DerivationInfo(derivationType: DerivationType.nano);
    } else if (credentials.walletInfo!.derivationInfo!.derivationType == null) {
      credentials.walletInfo!.derivationInfo!.derivationType = DerivationType.nano;
    }

    final wallet = await NanoWallet(
      password: credentials.password!,
      mnemonic: mnemonic ?? credentials.seedKey,
      walletInfo: credentials.walletInfo!,
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

    DerivationType derivationType =
        credentials.walletInfo?.derivationInfo?.derivationType ?? DerivationType.nano;

    credentials.walletInfo!.derivationInfo ??= DerivationInfo(derivationType: derivationType);

    final wallet = await NanoWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
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
    final walletInfo =
        walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(name, getType()));

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
