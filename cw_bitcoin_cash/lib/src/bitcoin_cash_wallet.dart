import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import 'bitcoin_cash_base.dart';

part 'bitcoin_cash_wallet.g.dart';

class BitcoinCashWallet = BitcoinCashWalletBase with _$BitcoinCashWallet;

abstract class BitcoinCashWalletBase extends ElectrumWallet with Store {
  BitcoinCashWalletBase(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required Uint8List seedBytes,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0})
      : super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            unspentCoinsInfo: unspentCoinsInfo,
            networkType: bitcoin.bitcoin,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance,
            seedBytes: seedBytes,
            currency: CryptoCurrency.bch) {
    walletAddresses = BitcoinCashWalletAddresses(walletInfo,
        electrumClient: electrumClient,
        initialAddresses: initialAddresses,
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex,
        mainHd: hd,
        sideHd: hd,
        //TODO: BCH check if this is correct
        networkType: networkType);
  }

  static Future<BitcoinCashWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0}) async {
    return BitcoinCashWallet(
        mnemonic: mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: initialAddresses,
        initialBalance: initialBalance,
        seedBytes: await Mnemonic.toSeed(mnemonic),
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex);
  }

  static Future<BitcoinCashWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
  }) async {
    final snp = await ElectrumWallletSnapshot.load(name, walletInfo.type, password);
    return BitcoinCashWallet(
        mnemonic: snp.mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: snp.addresses,
        initialBalance: snp.balance,
        seedBytes: await Mnemonic.toSeed(snp.mnemonic),
        initialRegularAddressIndex: snp.regularAddressIndex,
        initialChangeAddressIndex: snp.changeAddressIndex);
  }
}
