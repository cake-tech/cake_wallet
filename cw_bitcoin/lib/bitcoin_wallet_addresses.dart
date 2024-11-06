import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase with _$BitcoinWalletAddresses;

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.network,
    required super.isHardwareWallet,
    required super.hdWallets,
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
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) {
    final hdWallet = hdWallets[derivationType]!;

    if (derivationType == CWBitcoinDerivationType.old) {
      final pub = hdWallet
          .childKey(Bip32KeyIndex(isChange ? 1 : 0))
          .childKey(Bip32KeyIndex(index))
          .publicKey;

      switch (addressType) {
        case P2pkhAddressType.p2pkh:
          return ECPublic.fromBip32(pub).toP2pkhAddress();
        case SegwitAddresType.p2tr:
          return ECPublic.fromBip32(pub).toP2trAddress();
        case SegwitAddresType.p2wsh:
          return ECPublic.fromBip32(pub).toP2wshAddress();
        case P2shAddressType.p2wpkhInP2sh:
          return ECPublic.fromBip32(pub).toP2wpkhInP2sh();
        case SegwitAddresType.p2wpkh:
          return ECPublic.fromBip32(pub).toP2wpkhAddress();
        default:
          throw ArgumentError('Invalid address type');
      }
    }

    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return P2pkhAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      case SegwitAddresType.p2tr:
        return P2trAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      case SegwitAddresType.p2wsh:
        return P2wshAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      case P2shAddressType.p2wpkhInP2sh:
        return P2shAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
          type: P2shAddressType.p2wpkhInP2sh,
        );
      case SegwitAddresType.p2wpkh:
        return P2wpkhAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      default:
        throw ArgumentError('Invalid address type');
    }
  }
}
