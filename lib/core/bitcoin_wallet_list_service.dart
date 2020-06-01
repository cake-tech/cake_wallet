import 'dart:io';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/core/wallet_list_service.dart';
import 'package:cake_wallet/core/bitcoin_wallet.dart';
import 'package:cake_wallet/src/domain/common/pathForWallet.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/wallets_manager.dart';
/*
*
* BitcoinRestoreWalletFromSeedCredentials
*
* */

class BitcoinNewWalletCredentials extends WalletCredentials {}

/*
*
* BitcoinRestoreWalletFromSeedCredentials
*
* */

class BitcoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  const BitcoinRestoreWalletFromSeedCredentials(
      {String name, String password, this.mnemonic})
      : super(name: name, password: password);

  final String mnemonic;
}

/*
*
* BitcoinRestoreWalletFromWIFCredentials
*
* */

class BitcoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  const BitcoinRestoreWalletFromWIFCredentials(
      {String name, String password, this.wif})
      : super(name: name, password: password);

  final String wif;
}

/*
*
* BitcoinWalletListService
*
* */

class BitcoinWalletListService extends WalletListService<
    BitcoinNewWalletCredentials,
    BitcoinRestoreWalletFromSeedCredentials,
    BitcoinRestoreWalletFromWIFCredentials> {
  @override
  Future<void> create(BitcoinNewWalletCredentials credentials) async {
    final wallet = await BitcoinWalletBase.build(
        mnemonic: bip39.generateMnemonic(),
        password: credentials.password,
        name: credentials.name);
    await wallet.save();

    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: WalletType.bitcoin))
          .existsSync();

  @override
  Future<void> openWallet(String name, String password) async {
    // TODO: implement openWallet
    throw UnimplementedError();
  }

  Future<void> remove(String wallet) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<void> restoreFromKeys(
      BitcoinRestoreWalletFromWIFCredentials credentials) async {
    // TODO: implement restoreFromKeys
    throw UnimplementedError();
  }

  @override
  Future<void> restoreFromSeed(
      BitcoinRestoreWalletFromSeedCredentials credentials) async {
    final wallet = await BitcoinWalletBase.build(
        name: credentials.name,
        password: credentials.password,
        mnemonic: credentials.mnemonic);
    await wallet.save();

    return wallet;
  }
}
