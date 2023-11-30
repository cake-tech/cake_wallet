import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'litecoin_wallet_addresses.g.dart';

class LitecoinWalletAddresses = LitecoinWalletAddressesBase with _$LitecoinWalletAddresses;

abstract class LitecoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  LitecoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHd,
    required super.sideHd,
    required super.networkType,
    required super.transactionHistory,
    super.initialAddresses,
    super.initialRegularAddressIndex = 0,
    super.initialChangeAddressIndex = 0,
  }) : super(walletInfo);

  @override
  String getAddress({required int index, required HDWallet hd, AddressType? addressType}) =>
      generateP2WPKHAddress(hd: hd, index: index, networkType: networkType);
}
