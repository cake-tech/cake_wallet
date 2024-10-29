import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_cash_wallet_addresses.g.dart';

class BitcoinCashWalletAddresses = BitcoinCashWalletAddressesBase with _$BitcoinCashWalletAddresses;

abstract class BitcoinCashWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinCashWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.bip32,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
    super.initialAddressPageType,
  }) : super(walletInfo);

  @override
  BitcoinBaseAddress generateAddress({
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
  }) =>
      P2pkhAddress.fromBip32(bip32: bip32, isChange: isChange, index: index);
}
