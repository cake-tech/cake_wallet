import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';

part 'bitcoin_wallet.g.dart';

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends ElectrumWallet with Store {
  BitcoinWalletBase(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      bitcoin.NetworkType? networkType,
      required Uint8List seedBytes,
      required EncryptionFileUtils encryptionFileUtils,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0,
      bitcoin.SilentPaymentReceiver? silentAddress})
      : super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            unspentCoinsInfo: unspentCoinsInfo,
            networkType: networkType ?? bitcoin.bitcoin,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance,
            seedBytes: seedBytes,
            currency: CryptoCurrency.btc,
            encryptionFileUtils: encryptionFileUtils) {
    walletAddresses = BitcoinWalletAddresses(walletInfo,
        electrumClient: electrumClient,
        initialAddresses: initialAddresses,
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex,
        mainHd: hd,
        sideHd: bitcoin.HDWallet.fromSeed(seedBytes, network: networkType).derivePath("m/0'/1"),
        networkType: networkType ?? bitcoin.bitcoin,
        silentAddress: silentAddress);
  }

  static Future<BitcoinWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      bitcoin.NetworkType? networkType,
      required EncryptionFileUtils encryptionFileUtils,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0}) async {
    return BitcoinWallet(
        mnemonic: mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        networkType: networkType,
        initialAddresses: initialAddresses,
        initialBalance: initialBalance,
        encryptionFileUtils: encryptionFileUtils,
        seedBytes: await mnemonicToSeedBytes(mnemonic),
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex,
        silentAddress: await bitcoin.SilentPaymentReceiver.fromMnemonic(mnemonic,
            hrp: networkType == bitcoin.bitcoin ? 'sp' : 'tsp'));
  }

  static Future<BitcoinWallet> open(
      {required String name,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required String password,
      required EncryptionFileUtils encryptionFileUtils}) async {
    final snp =
        await ElectrumWallletSnapshot.load(encryptionFileUtils, name, walletInfo.type, password);
    return BitcoinWallet(
        mnemonic: snp.mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        networkType: snp.networkType,
        initialAddresses: snp.addresses,
        initialBalance: snp.balance,
        seedBytes: await mnemonicToSeedBytes(snp.mnemonic),
        encryptionFileUtils: encryptionFileUtils,
        initialRegularAddressIndex: snp.regularAddressIndex,
        initialChangeAddressIndex: snp.changeAddressIndex,
        silentAddress: await bitcoin.SilentPaymentReceiver.fromMnemonic(snp.mnemonic,
            hrp: snp.networkType == bitcoin.bitcoin ? 'sp' : 'tsp'));
  }
}
