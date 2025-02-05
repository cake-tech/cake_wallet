import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin_cash/cw_bitcoin_cash.dart';
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
    super.initialAddresses,
    super.initialAddressPageType,
  }) : super(walletInfo);

  @override
  final walletAddressTypes = BITCOIN_CASH_ADDRESS_TYPES;

  static const BITCOIN_CASH_ADDRESS_TYPES = [P2pkhAddressType.p2pkh];

  @override
  Future<void> init() async {
    await generateInitialAddresses(type: P2pkhAddressType.p2pkh);
    await super.init();
  }

  @override
  BitcoinBaseAddress generateAddress({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) =>
      P2pkhAddress.fromDerivation(
        bip32: hdWallet,
        derivationInfo: derivationInfo,
        isChange: isChange,
        index: index,
      );

  static BitcoinCashWalletAddressesBase fromJson(
    Map<String, dynamic> json,
    WalletInfo walletInfo, {
    required Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets,
    required BasedUtxoNetwork network,
    required bool isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
  }) {
    initialAddresses ??= (json['allAddresses'] as List).map((addr) {
      try {
        BitcoinCashAddress(addr.address);
        return BitcoinAddressRecord(
          addr.address,
          index: addr.index,
          isChange: addr.isChange,
          type: P2pkhAddressType.p2pkh,
          network: BitcoinCashNetwork.mainnet,
          derivationInfo: BitcoinAddressUtils.getDerivationFromType(P2pkhAddressType.p2pkh),
          cwDerivationType: CWBitcoinDerivationType.bip39,
        );
      } catch (_) {
        return BitcoinAddressRecord(
          AddressUtils.getCashAddrFormat(addr.address),
          index: addr.index,
          isChange: addr.isChange,
          type: P2pkhAddressType.p2pkh,
          network: BitcoinCashNetwork.mainnet,
          derivationInfo: BitcoinAddressUtils.getDerivationFromType(P2pkhAddressType.p2pkh),
          cwDerivationType: CWBitcoinDerivationType.bip39,
        );
      }
    }).toList();

    return BitcoinCashWalletAddresses(
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
      initialAddresses: initialAddresses,
    );
  }
}
