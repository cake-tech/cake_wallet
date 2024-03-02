import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_cash_wallet_addresses.g.dart';

class BitcoinCashWalletAddresses = BitcoinCashWalletAddressesBase with _$BitcoinCashWalletAddresses;

abstract class BitcoinCashWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinCashWalletAddressesBase(WalletInfo walletInfo,
      {required bitcoin.HDWallet mainHd,
      required bitcoin.HDWallet sideHd,
      required bitcoin.NetworkType networkType,
      required ElectrumClient electrumClient,
      List<BitcoinAddressRecord>? initialAddresses,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0})
      : super(walletInfo,
            initialAddresses: initialAddresses,
            initialRegularAddressIndex: initialRegularAddressIndex,
            initialChangeAddressIndex: initialChangeAddressIndex,
            mainHd: mainHd,
            sideHd: sideHd,
            electrumClient: electrumClient,
            networkType: networkType);

  @override
  String getAddress({required int index, required bitcoin.HDWallet hd}) =>
      generateP2PKHAddress(hd: hd, index: index, networkType: networkType);
}
