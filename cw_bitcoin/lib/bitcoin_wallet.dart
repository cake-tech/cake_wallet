import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
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
      {@required String mnemonic,
      @required String password,
      @required WalletInfo walletInfo,
      @required Box<UnspentCoinsInfo> unspentCoinsInfo,
      List<BitcoinAddressRecord> initialAddresses,
      ElectrumBalance initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0})
      : super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            unspentCoinsInfo: unspentCoinsInfo,
            networkType: bitcoin.bitcoin,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance) {
    walletAddresses = BitcoinWalletAddresses(
        walletInfo,
        electrumClient: electrumClient,
        initialAddresses: initialAddresses,
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex,
        mainHd: hd,
        sideHd: bitcoin.HDWallet.fromSeed(
                mnemonicToSeedBytes(mnemonic), network: networkType)
              .derivePath("m/0'/1"),
        networkType: networkType);
  }

  static Future<BitcoinWallet> open({
    @required String name,
    @required WalletInfo walletInfo,
    @required Box<UnspentCoinsInfo> unspentCoinsInfo,
    @required String password,
  }) async {
    final snp = ElectrumWallletSnapshot(name, walletInfo.type, password);
    await snp.load();
    return BitcoinWallet(
        mnemonic: snp.mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: snp.addresses,
        initialBalance: snp.balance,
        initialRegularAddressIndex: snp.regularAddressIndex,
        initialChangeAddressIndex: snp.changeAddressIndex);
  }
}
