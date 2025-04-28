import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/seedbyte_types.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_cash_wallet_addresses.g.dart';

class BitcoinCashWalletAddresses = BitcoinCashWalletAddressesBase with _$BitcoinCashWalletAddresses;

abstract class BitcoinCashWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinCashWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.hdWallets,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddressesRecords,
    super.initialActiveAddressIndex,
    super.initialAddressPageType,
  }) : super(walletInfo);

  @override
  final walletAddressTypes = [P2pkhAddressType.p2pkh];

  @override
  BitcoinAddressType changeAddressType = P2pkhAddressType.p2pkh;

  @override
  BitcoinAddressType get addressPageType => P2pkhAddressType.p2pkh;

  static BitcoinCashWalletAddressesBase fromJson(
    Map<String, dynamic> json,
    WalletInfo walletInfo, {
    required Map<SeedBytesType, Bip32Slip10Secp256k1> hdWallets,
    required BasedUtxoNetwork network,
    required bool isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
  }) {
    final electrumJson = ElectrumWalletAddressesBase.fromJson(
      json,
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
    );

    return BitcoinCashWalletAddresses(
      electrumJson.walletInfo,
      hdWallets: electrumJson.hdWallets,
      network: electrumJson.network,
      isHardwareWallet: electrumJson.isHardwareWallet,
      initialAddressesRecords: electrumJson.addressesRecords,
      initialAddressPageType: electrumJson.addressPageType,
      initialActiveAddressIndex: electrumJson.activeIndexByType,
    );
  }
}
