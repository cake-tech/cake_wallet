import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase with _$BitcoinWalletAddresses;

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.bip32,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
    super.initialSilentAddresses,
    super.initialSilentAddressIndex = 0,
  }) : super(walletInfo);

  @override
  BitcoinBaseAddress generateAddress({
    required int account,
    required int index,
    required Bip32Slip10Secp256k1 hd,
    required BitcoinAddressType addressType,
  }) {
    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return P2pkhAddress.fromBip32(account: account, bip32: hd, index: index);
      case SegwitAddresType.p2tr:
        return P2trAddress.fromBip32(account: account, bip32: hd, index: index);
      case SegwitAddresType.p2wsh:
        return P2wshAddress.fromBip32(account: account, bip32: hd, index: index);
      case P2shAddressType.p2wpkhInP2sh:
        return P2shAddress.fromBip32(
          account: account,
          bip32: hd,
          index: index,
          type: P2shAddressType.p2wpkhInP2sh,
        );
      case SegwitAddresType.p2wpkh:
        return P2wpkhAddress.fromBip32(account: account, bip32: hd, index: index);
      default:
        throw ArgumentError('Invalid address type');
    }
  }
}
