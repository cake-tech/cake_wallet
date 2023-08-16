import 'dart:io';

import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_client.dart';
import 'package:cw_nano/nano_mnemonic.dart' as nm;
import 'package:cw_nano/nano_util.dart';
import 'package:cw_nano/nano_wallet.dart';
import 'package:hive/hive.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:nanodart/nanodart.dart';

class NanoNewWalletCredentials extends WalletCredentials {
  NanoNewWalletCredentials({required String name, String? password})
      : super(name: name, password: password);
}

class NanoRestoreWalletFromSeedCredentials extends WalletCredentials {
  NanoRestoreWalletFromSeedCredentials(
      {required String name,
      required this.mnemonic,
      this.derivationType,
      int height = 0,
      String? password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
  final DerivationType? derivationType;
}

class NanoWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class NanoRestoreWalletFromKeysCredentials extends WalletCredentials {
  NanoRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required this.seedKey,
    this.derivationType,
  }) : super(name: name, password: password);

  final String seedKey;
  final DerivationType? derivationType;
}

class NanoWalletService extends WalletService<NanoNewWalletCredentials,
    NanoRestoreWalletFromSeedCredentials, NanoRestoreWalletFromKeysCredentials> {
  NanoWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.nano;

  @override
  Future<WalletBase> create(NanoNewWalletCredentials credentials) async {
    // nano standard:
    DerivationType derivationType = DerivationType.nano;
    String seedKey = NanoSeeds.generateSeed();
    String mnemonic = NanoUtil.seedToMnemonic(seedKey);

    // bip39:
    // derivationType derivationType = DerivationType.bip39;
    // String mnemonic = bip39.generateMnemonic();

    credentials.walletInfo!.derivationType = derivationType;

    final wallet = NanoWallet(
      walletInfo: credentials.walletInfo!,
      mnemonic: mnemonic,
      password: credentials.password!,
    );
    wallet.init();
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

    currentWalletInfo.derivationType = DerivationType.nano; // doesn't matter for the rename action

    String randomWords =
        (List<String>.from(nm.NanoMnemomics.WORDLIST)..shuffle()).take(24).join(' ');
    final currentWallet =
        NanoWallet(walletInfo: currentWalletInfo, password: password, mnemonic: randomWords);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  static Future<dynamic> getInfoFromSeedOrMnemonic(
    DerivationType derivationType, {
    String? seedKey,
    String? mnemonic,
    required Node node,
  }) async {
    NanoClient nanoClient = NanoClient();
    nanoClient.connect(node);
    late String publicAddress;

    if (seedKey != null) {
      if (derivationType == DerivationType.bip39) {
        publicAddress = await NanoUtil.hdSeedToAddress(seedKey, 0);
      } else if (derivationType == DerivationType.nano) {
        publicAddress = await NanoUtil.seedToAddress(seedKey, 0);
      }
    }

    if (derivationType == DerivationType.bip39) {
      if (mnemonic != null) {
        seedKey = await NanoUtil.hdMnemonicListToSeed(mnemonic.split(' '));
        publicAddress = await NanoUtil.hdSeedToAddress(seedKey, 0);
      }
    }

    if (derivationType == DerivationType.nano) {
      if (mnemonic != null) {
        seedKey = await NanoUtil.mnemonicToSeed(mnemonic);
        publicAddress = await NanoUtil.seedToAddress(seedKey, 0);
      }
    }

    var accountInfo = await nanoClient.getAccountInfo(publicAddress);
    accountInfo["address"] = publicAddress;
    return accountInfo;
  }

  static Future<List<DerivationType>> compareDerivationMethods(
      {String? mnemonic, String? seedKey, required Node node}) async {
    if (mnemonic?.split(' ').length == 12) {
      return [DerivationType.bip39];
    }
    if (seedKey?.length == 128) {
      return [DerivationType.bip39];
    } else if (seedKey?.length == 64) {
      return [DerivationType.nano];
    }

    late String publicAddressStandard;
    late String publicAddressBip39;

    try {
      NanoClient nanoClient = NanoClient();
      nanoClient.connect(node);

      if (mnemonic != null) {
        seedKey = await NanoUtil.hdMnemonicListToSeed(mnemonic.split(' '));
        publicAddressBip39 = await NanoUtil.hdSeedToAddress(seedKey, 0);

        seedKey = await NanoUtil.mnemonicToSeed(mnemonic);
        publicAddressStandard = await NanoUtil.seedToAddress(seedKey, 0);
      } else if (seedKey != null) {
        try {
          publicAddressBip39 = await NanoUtil.hdSeedToAddress(seedKey, 0);
        } catch (e) {
          return [DerivationType.nano];
        }
        try {
          publicAddressStandard = await NanoUtil.seedToAddress(seedKey, 0);
        } catch (e) {
          return [DerivationType.bip39];
        }
      }

      // check if account has a history:
      var bip39Info;
      var standardInfo;

      try {
        bip39Info = await nanoClient.getAccountInfo(publicAddressBip39);
      } catch (e) {
        bip39Info = null;
      }
      try {
        standardInfo = await nanoClient.getAccountInfo(publicAddressStandard);
      } catch (e) {
        standardInfo = null;
      }

      // one of these is *probably* null:
      if ((bip39Info == null || bip39Info["error"] != null) &&
          (standardInfo != null && standardInfo["error"] == null)) {
        return [DerivationType.nano];
      } else if ((standardInfo == null || standardInfo["error"] != null) &&
          (bip39Info != null && bip39Info["error"] == null)) {
        return [DerivationType.bip39];
      }

      // we don't know for sure:
      return [DerivationType.nano, DerivationType.bip39];
    } catch (e) {
      return [DerivationType.unknown];
    }
  }

  @override
  Future<NanoWallet> restoreFromKeys(NanoRestoreWalletFromKeysCredentials credentials) async {
    if (credentials.seedKey.contains(' ')) {
      throw Exception("Invalid key!");
    } else {
      if (credentials.seedKey.length != 64 && credentials.seedKey.length != 128) {
        throw Exception("Invalid key length!");
      }
    }

    DerivationType derivationType = credentials.derivationType ?? DerivationType.nano;
    credentials.walletInfo!.derivationType = derivationType;

    final wallet = await NanoWallet(
      password: credentials.password!,
      mnemonic: credentials.seedKey, // we can't derive the mnemonic from the key in all cases
      walletInfo: credentials.walletInfo!,
    );
    await wallet.init();
    await wallet.save();
    return wallet;
  }

  @override
  Future<NanoWallet> restoreFromSeed(NanoRestoreWalletFromSeedCredentials credentials) async {
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

    DerivationType derivationType = credentials.derivationType ?? DerivationType.nano;

    credentials.walletInfo!.derivationType = derivationType;

    final wallet = await NanoWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
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
    final wallet = await NanoWalletBase.open(
      name: name,
      password: password,
      walletInfo: walletInfo,
    );

    await wallet.init();
    await wallet.save();
    return wallet;
  }
}
