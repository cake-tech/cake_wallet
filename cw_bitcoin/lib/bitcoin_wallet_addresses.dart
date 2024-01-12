import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase with _$BitcoinWalletAddresses;

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHd,
    required super.sideHd,
    required super.network,
    required super.electrumClient,
    super.initialAddresses,
    super.initialRegularAddressIndex = const {},
    super.initialChangeAddressIndex = const {},
  }) : super(walletInfo);

  @override
  String getAddress({required int index, required HDWallet hd, BitcoinAddressType? addressType}) {
    if (addressType == BitcoinAddressType.p2pkh)
      return generateP2PKHAddress(hd: hd, index: index, network: network);

    if (addressType == BitcoinAddressType.p2tr)
      return generateP2TRAddress(hd: hd, index: index, network: network);

    if (addressType == BitcoinAddressType.p2wsh)
      return generateP2WSHAddress(hd: hd, index: index, network: network);

    return generateP2WPKHAddress(hd: hd, index: index, network: network);
  }
}
