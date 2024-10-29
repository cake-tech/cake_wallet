import 'package:bitcoin_base/bitcoin_base.dart';
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
  Future<void> init() async {
    await generateInitialAddresses(type: SegwitAddresType.p2wpkh);

    if (!isHardwareWallet) {
      await generateInitialAddresses(type: P2pkhAddressType.p2pkh);
      await generateInitialAddresses(type: P2shAddressType.p2wpkhInP2sh);
      await generateInitialAddresses(type: SegwitAddresType.p2tr);
      await generateInitialAddresses(type: SegwitAddresType.p2wsh);
    }

    await updateAddressesInBox();
  }

  @override
  BitcoinBaseAddress generateAddress({
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
  }) {
    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return P2pkhAddress.fromBip32(bip32: bip32, isChange: isChange, index: index);
      case SegwitAddresType.p2tr:
        return P2trAddress.fromBip32(bip32: bip32, isChange: isChange, index: index);
      case SegwitAddresType.p2wsh:
        return P2wshAddress.fromBip32(bip32: bip32, isChange: isChange, index: index);
      case P2shAddressType.p2wpkhInP2sh:
        return P2shAddress.fromBip32(
          bip32: bip32,
          isChange: isChange,
          index: index,
          type: P2shAddressType.p2wpkhInP2sh,
        );
      case SegwitAddresType.p2wpkh:
        return P2wpkhAddress.fromBip32(
          bip32: bip32,
          isChange: isChange,
          index: index,
          isElectrum: false, // TODO:
        );
      default:
        throw ArgumentError('Invalid address type');
    }
  }
}
