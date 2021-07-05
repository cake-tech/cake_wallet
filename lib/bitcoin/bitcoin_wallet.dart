import 'package:cake_wallet/bitcoin/unspent_coins_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/bitcoin/utils.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet_snapshot.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';
import 'package:cake_wallet/bitcoin/electrum_balance.dart';

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
      int accountIndex = 0})
      : super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            unspentCoinsInfo: unspentCoinsInfo,
            networkType: bitcoin.bitcoin,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance,
            accountIndex: accountIndex);

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
        accountIndex: snp.accountIndex);
  }

  @override
  String getAddress({@required int index, @required bitcoin.HDWallet hd}) =>
      generateP2WPKHAddress(hd: hd, index: index, networkType: networkType);
}
