import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/silent_payments_wallet_addresses.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase with _$BitcoinWalletAddresses;

abstract class BitcoinWalletAddressesBase extends SilentPaymentsWalletAddresses {
  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.network,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
    super.initialSilentAddresses,
    super.initialSilentAddressIndex = 0,
    required super.accountHD,
  }) : super(walletInfo);

  @override
  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) {
    final publicKey = generateECPublic(hd, index);

    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return publicKey.toP2pkhAddress().toAddress(network);
      case SegwitAddresType.p2tr:
        return publicKey.toTaprootAddress().toAddress(network);
      case SegwitAddresType.p2wsh:
        return publicKey.toP2wshAddress().toAddress(network);
      case P2shAddressType.p2wpkhInP2sh:
        return publicKey.toP2wpkhInP2sh().toAddress(network);
      default:
        return publicKey.toP2wpkhAddress().toAddress(network);
    }
  }
}
