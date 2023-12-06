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
    required super.networkType,
    required super.transactionHistory,
    super.initialAddresses,
    super.initialSilentAddresses,
    super.initialRegularAddressIndex = 0,
    super.initialChangeAddressIndex = 0,
    super.initialSilentAddressIndex = 0,
    super.silentAddress,
  }) : super(walletInfo);

  @override
  String getAddress({required int index, required HDWallet hd, AddressType? addressType}) {
    if (addressType == AddressType.p2pkh)
      return generateP2PKHAddress(hd: hd, index: index, networkType: networkType);

    if (addressType == AddressType.p2tr)
      return generateP2TRAddress(hd: hd, index: index, networkType: networkType);

    return generateP2WPKHAddress(hd: hd, index: index, networkType: networkType);
  }
}
