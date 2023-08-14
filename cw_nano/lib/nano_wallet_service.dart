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

    currentWalletInfo.derivationType = DerivationType.nano;// doesn't matter for the rename action

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

  static Future<DerivationType> compareDerivationMethods({String? mnemonic, String? seedKey}) async {
    if (mnemonic?.split(' ').length == 12) {
      return DerivationType.bip39;
    }
    if (seedKey?.length == 128) {
      return DerivationType.bip39;
    } else if (seedKey?.length == 64) {
      return DerivationType.nano;
    }

    late String publicAddressStandard;
    late String publicAddressBip39;

    try {
      NanoClient nanoClient = NanoClient();
      // TODO: figure out how to load the current node uri in this context:
      nanoClient.connect(Node(
        uri: NanoClient.BACKUP_NODE_URI,
        type: WalletType.nano,
      ));

      if (mnemonic != null) {
        seedKey = await NanoUtil.hdMnemonicListToSeed(mnemonic.split(' '));
        publicAddressBip39 = await NanoUtil.hdSeedToAddress(seedKey, 0);

        seedKey = await NanoUtil.mnemonicToSeed(mnemonic);
        publicAddressStandard = await NanoUtil.seedToAddress(seedKey, 0);
      } else if (seedKey != null) {
        try {
          publicAddressBip39 = await NanoUtil.hdSeedToAddress(seedKey, 0);
        } catch (e) {
          return DerivationType.nano;
        }
        try {
          publicAddressStandard = await NanoUtil.seedToAddress(seedKey, 0);
        } catch (e) {
          return DerivationType.bip39;
        }
      }
      // check if either has a balance:
      // NanoBalance bip39Balance = await nanoClient.getBalance(publicAddressBip39);
      // NanoBalance standardBalance = await nanoClient.getBalance(publicAddressStandard);
      // // TODO: this is a super basic implementation, and if both addresses have balances
      // // it might not be the one that the user wants, though it is unlikely
      // if (bip39Balance.currentBalance > standardBalance.currentBalance) {
      //   return DerivationType.bip39;
      // } else {
      //   return DerivationType.nano;
      // }

      // check if account has a history:
      var bip39Info;
      var standardInfo;

      print(publicAddressBip39);
      print(publicAddressStandard);

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
      if (bip39Info == null || bip39Info["error"] != null) {
        return DerivationType.nano;
      } else if (standardInfo == null || standardInfo["error"] != null) {
        return DerivationType.bip39;
      }

      // both are non-null:
      var bip39Height = int.parse(bip39Info['confirmation_height'] as String);
      var standardHeight = int.parse(standardInfo['confirmation_height'] as String);

      print(bip39Height);
      print(standardHeight);

      if (bip39Height > standardHeight) {
        return DerivationType.bip39;
      } else {
        return DerivationType.nano;
      }
    } catch (e) {
      return DerivationType.nano;
    }
  }

  @override
  Future<NanoWallet> restoreFromKeys(NanoRestoreWalletFromKeysCredentials credentials) async {
    throw UnimplementedError("restoreFromKeys");

    // TODO: mnemonic can't be derived from the seedKey in the nano standard derivation
    // which complicates things

    // DerivationType derivationType = credentials.derivationType ?? await compareDerivationMethods(seedKey: credentials.seedKey);
    // String? mnemonic;
    // final nanoWalletInfo = NanoWalletInfo(
    //   walletInfo: credentials.walletInfo!,
    //   derivationType: derivationType,
    // );
    // final wallet = await NanoWallet(
    //   password: credentials.password!,
    //   mnemonic: mnemonic ?? "", // we can't derive the mnemonic from the key in all cases
    //   walletInfo: nanoWalletInfo,
    // );
    // await wallet.init();
    // await wallet.save();
    // return wallet;
  }

  @override
  Future<NanoWallet> restoreFromSeed(NanoRestoreWalletFromSeedCredentials credentials) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw nm.NanoMnemonicIsIncorrectException();
    }

    if (!NanoMnemomics.validateMnemonic(credentials.mnemonic.split(' '))) {
      throw nm.NanoMnemonicIsIncorrectException();
    }

    DerivationType derivationType = credentials.derivationType ??
        await compareDerivationMethods(mnemonic: credentials.mnemonic);

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
