import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'litecoin_wallet_addresses.g.dart';

class LitecoinWalletAddresses = LitecoinWalletAddressesBase
    with _$LitecoinWalletAddresses;

abstract class LitecoinWalletAddressesBase extends ElectrumWalletAddresses
    with Store {
  LitecoinWalletAddressesBase(
      WalletInfo walletInfo,
      {@required List<BitcoinAddressRecord> initialAddresses,
        int initialRegularAddressIndex = 0,
        int initialChangeAddressIndex = 0,
        ElectrumClient electrumClient,
        @required bitcoin.HDWallet mainHd,
        @required bitcoin.HDWallet sideHd,
        @required bitcoin.NetworkType networkType})
      : super(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHd: mainHd,
      sideHd: sideHd,
      electrumClient: electrumClient,
      networkType: networkType);

  @override
  String getAddress({@required int index, @required bitcoin.HDWallet hd}) =>
      generateP2WPKHAddress(hd: hd, index: index, networkType: networkType);
}