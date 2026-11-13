import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:cw_pivx/src/pivx_receive_page_options.dart';
import 'package:mobx/mobx.dart';

part 'pivx_wallet_addresses.g.dart';

/// m/44'/119'/account'/change/index. Prefixes: 'D' P2PKH, '6' P2SH (mainnet),
/// 'ps1' Sapling. No SegWit.
class PivxWalletAddresses = PivxWalletAddressesBase with _$PivxWalletAddresses;

abstract class PivxWalletAddressesBase extends ElectrumWalletAddresses
    with Store {
  PivxWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHdByTypeAndAccount,
    required super.sideHdByTypeAndAccount,
    required super.accountIndexes,
    required super.currentAccountIndex,
    required super.legacyMainHd,
    required super.legacySideHd,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
    super.initialAddressPageType,
  }) : super(walletInfo);

  @override
  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) =>
      generateP2PKHAddress(hd: hd, index: index, network: network);

  /// Mirrors PivxWallet.saplingEnabled. Plain field: stable by the time the
  /// receive page opens.
  bool saplingEnabled = true;

  /// The base single "mainnet" option hides the type picker.
  @override
  List<ReceivePageOption> get receivePageOptions => saplingEnabled
      ? PivxReceivePageOption.all
      : const [PivxReceivePageOption.transparent];

  @override
  PaymentURI getPaymentUri(String amount) =>
      PivxURI(amount: amount, address: address);

  /// Display only; Sapling addresses are not in the regular address list.
  @observable
  String? selectedShieldedAddress;

  @override
  @computed
  String get address {
    if (selectedShieldedAddress != null) {
      return selectedShieldedAddress!;
    }
    return super.address;
  }

  // Exchange and buy providers pay transparent addresses only; the shielded
  // selection is for the receive page.
  @override
  String get addressForExchange {
    getFreshAddress();
    return super.address;
  }

  // As Bitcoin: a hidden (swap refund) or used address must not be handed to a
  // buy provider.
  @override
  String get addressForBuy {
    try {
      return allAddresses
          .firstWhere((e) =>
              e.accountIndex == currentAccountIndex &&
              e.type == P2pkhAddressType.p2pkh &&
              !e.isHidden &&
              !e.isUsed &&
              !hiddenAddresses.contains(e.address))
          .address;
    } catch (_) {
      return super.address;
    }
  }

  void clearShieldedSelection() {
    selectedShieldedAddress = null;
  }

  @override
  set address(String addr) {
    if (addr.startsWith('ps')) {
      // A string that fails the checksum must not become the receive address.
      if (PivxNetwork.isValidAddress(addr)) selectedShieldedAddress = addr;
      return;
    }
    selectedShieldedAddress = null;
    super.address = addr;
  }
}
