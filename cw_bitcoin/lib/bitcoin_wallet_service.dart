import 'dart:io';
import 'package:cw_bitcoin/address_to_output_script.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic_is_incorrect_exception.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_bitcoin/utils.dart';
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
import 'package:cw_bitcoin/bitcoin_derivations.dart';

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
    // TODO: figure out what the default derivation path is
    credentials.walletInfo!.derivationPath = "m/0'/1";
    final wallet = await BitcoinWalletBase.create(
        mnemonic: await generateElectrumMnemonic(strength: 132),
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
      {required String mnemonic, required Node node}) async {
    // if the mnemonic is 12 words, then it could be electrum 1.0,
    // if the mnemonic is 24 words, then it could be electrum 2.0
    // bip39 is possible with any number of words
    int wordCount = mnemonic.split(" ").length;
    if (wordCount == 24) {
      return [DerivationType.bip39, DerivationType.electrum1];
    } else if (wordCount == 12) {
      return [DerivationType.bip39, DerivationType.electrum2];
    } else {
      return [DerivationType.bip39];
    }
  }

  static Future<List<DerivationInfo>> getDerivationsFromMnemonic(
      {required String mnemonic, required Node node}) async {
    List<DerivationInfo> list = [];

    final electrumClient = ElectrumClient();
    await electrumClient.connectToUri(node.uri);

    for (DerivationType dType in bitcoin_derivations.keys) {
      if (dType == DerivationType.bip39) {
        for (DerivationInfo dInfo in bitcoin_derivations[dType]!) {
          try {
            var wallet = bitcoin.HDWallet.fromSeed(await mnemonicToSeedBytes(mnemonic),
                    network: bitcoin.bitcoin)
                .derivePath(dInfo.derivationPath!);

            String? address;
            switch (dInfo.script_type) {
              case "p2wpkh":
                address = bitcoin
                    .P2WPKH(
                        data: generatePaymentData(hd: wallet, index: 0), network: bitcoin.bitcoin)
                    .data
                    .address;
                break;
              case "p2pkh":
                address = bitcoin
                    .P2PKH(
                        data: generatePaymentData(hd: wallet, index: 0), network: bitcoin.bitcoin)
                    .data
                    .address;
                break;
              case "p2wpkh-p2sh":
              default:
                address = wallet.address;
                break;
            }

            // print(
            //     "${dInfo.derivationType.toString()} : ${dInfo.derivationPath} : ${dInfo.script_type} : ${address}");

            final sh = scriptHash(address!, networkType: bitcoin.bitcoin);
            final history = await electrumClient.getHistory(sh);

            final balance = await electrumClient.getBalance(sh);
            dInfo.balance = balance.entries.first.value.toString();
            dInfo.address = address;
            dInfo.height = history.length;

            list.add(dInfo);
          } catch (e) {
            print(e);
          }
        }
      }
    }

    return list;
  }

  static Future<dynamic> getInfoFromSeed({required String seed, required Node node}) async {
    throw UnimplementedError();
  }
}
