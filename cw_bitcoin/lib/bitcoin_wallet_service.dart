import 'dart:io';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic_is_incorrect_exception.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:mobx/mobx.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;

class BitcoinWalletService extends WalletService<BitcoinNewWalletCredentials,
    BitcoinRestoreWalletFromSeedCredentials, BitcoinRestoreWalletFromWIFCredentials> {
  BitcoinWalletService(this.walletInfoSource, this.unspentCoinsInfoSource);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;

  @override
  WalletType getType() => WalletType.bitcoin;

  @override
  Future<BitcoinWallet> create(BitcoinNewWalletCredentials credentials) async {
    // default derivation type/path for bitcoin wallets:
    // TODO: figure out what the default derivation type is
    // credentials.walletInfo!.derivationType = DerivationType.bip39;
    credentials.walletInfo!.derivationPath = "m/0'/1";

    final wallet = await BitcoinWalletBase.create(
        mnemonic: await generateMnemonic(),
        password: credentials.password!,
        walletInfo: credentials.walletInfo!,
        unspentCoinsInfo: unspentCoinsInfoSource);
    await wallet.save();
    await wallet.init();
    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<BitcoinWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(name, getType()))!;
    final wallet = await BitcoinWalletBase.open(
        password: password,
        name: name,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource);
    await wallet.init();
    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(wallet, getType()))!;
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(currentName, getType()))!;
    final currentWallet = await BitcoinWalletBase.open(
        password: password,
        name: currentName,
        walletInfo: currentWalletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<BitcoinWallet> restoreFromKeys(BitcoinRestoreWalletFromWIFCredentials credentials) async =>
      throw UnimplementedError();

  @override
  Future<BitcoinWallet> restoreFromSeed(BitcoinRestoreWalletFromSeedCredentials credentials) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw BitcoinMnemonicIsIncorrectException();
    }

    final wallet = await BitcoinWalletBase.create(
        password: credentials.password!,
        mnemonic: credentials.mnemonic,
        walletInfo: credentials.walletInfo!,
        unspentCoinsInfo: unspentCoinsInfoSource);
    await wallet.save();
    await wallet.init();
    return wallet;
  }

  static Future<List<DerivationType>> compareDerivationMethods(
      {required mnemonic, required Node node}) async {
    return [DerivationType.bip39, DerivationType.StandardBIP44Legacy];
  }

  static Future<List<DerivationInfo>> getDerivationsFromMnemonic(
      {required String mnemonic, required Node node}) async {
    // throw UnimplementedError();

    var list = [];
    final electrumClient = ElectrumClient();
    await electrumClient.connectToUri(node.uri);

    // default derivation path:
    var wallet =
        bitcoin.HDWallet.fromSeed(await mnemonicToSeedBytes(mnemonic), network: bitcoin.bitcoin)
            .derivePath("m/0'/1");

    // get addresses:
    final sh = scriptHash(wallet.address!, networkType: bitcoin.bitcoin);

    final balance = await electrumClient.getBalance(sh);

    print(wallet.address);
    print(balance.entries);
    print("@@@@@@@@@@@@@");

    // final wallet = await BitcoinWalletBase.create(
    //     password: "password",
    //     mnemonic: mnemonic,
    //     walletInfo: WalletInfo(
    //       "id",
    //       "test",
    //       WalletType.bitcoin,
    //       false,
    //       0,
    //       0,
    //       "dirPath",
    //       "path",
    //       "",
    //       null,
    //       "yatLastUsedAddressRaw",
    //       false,
    //       DerivationType.bip39,
    //       "derivationPath",
    //     ),
    //     unspentCoinsInfo: unspentCoinsInfoSource);

    list.add(DerivationInfo(
      "0.00000",
      "address",
      0,
      DerivationType.bip39,
      null,
    ));

    return [];
  }

  static Future<dynamic> getInfoFromSeed({required String seed, required Node node}) async {
    throw UnimplementedError();
  }
}
