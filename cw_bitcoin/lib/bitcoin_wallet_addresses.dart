import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase
    with _$BitcoinWalletAddresses;

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses
    with Store {
  BitcoinWalletAddressesBase(
      WalletInfo walletInfo,
      {@required List<BitcoinAddressRecord> initialAddresses,
        int accountIndex = 0,
        @required bitcoin.HDWallet mainHd,
        @required bitcoin.HDWallet sideHd,
        @required this.networkType})
      : super(
        walletInfo,
        initialAddresses: initialAddresses,
        accountIndex: accountIndex,
        mainHd: mainHd,
        sideHd: sideHd);

  bitcoin.NetworkType networkType;

  @override
  String getAddress({@required int index, @required bitcoin.HDWallet hd}) =>
      generateP2WPKHAddress(hd: hd, index: index, networkType: networkType);
}