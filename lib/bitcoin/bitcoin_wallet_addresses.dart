import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/bitcoin/utils.dart';
import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet_addresses.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
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
        @required bitcoin.HDWallet hd,
        @required this.networkType})
      : super(
        walletInfo,
        initialAddresses: initialAddresses,
        accountIndex: accountIndex,
        hd: hd);

  bitcoin.NetworkType networkType;

  @override
  String getAddress({@required int index, @required bitcoin.HDWallet hd}) =>
      generateP2WPKHAddress(hd: hd, index: index, networkType: networkType);
}