import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_pivx/src/pivx_receive_page_options.dart';
import 'package:mobx/mobx.dart';

part 'pivx_wallet_addresses.g.dart';

/// PIVX address management. BIP44 coin type 119
/// (m/44'/119'/account'/change/index). Address prefixes: 'D' P2PKH, '8' P2SH,
/// 'S' staking, 'ps1' Sapling. No native SegWit; follows the Electrum pattern.
class PivxWalletAddresses = PivxWalletAddressesBase with _$PivxWalletAddresses;

abstract class PivxWalletAddressesBase extends ElectrumWalletAddresses
    with Store {
  PivxWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHdByType,
    required super.sideHdByType,
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

  /// mirrors PivxWallet.saplingEnabled (pushed via [setSaplingEnabled]); gates
  /// whether the shielded receive option shows. plain field (stable by the time
  /// Receive opens), no mobx codegen needed.
  bool saplingEnabled = true;

  void setSaplingEnabled(bool value) => saplingEnabled = value;

  /// receive-page address types: transparent + shielded, or transparent-only
  /// when Sapling is unavailable. replaces the base single "mainnet" option that
  /// left the type picker hidden.
  @override
  List<ReceivePageOption> get receivePageOptions => saplingEnabled
      ? PivxReceivePageOption.all
      : const [PivxReceivePageOption.transparent];

  @override
  PaymentURI getPaymentUri(String amount) =>
      PivxURI(amount: amount, address: address);

  /// Selected shielded address (display only).
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

  /// Revert to the transparent address.
  void clearShieldedSelection() {
    selectedShieldedAddress = null;
  }

  @override
  set address(String addr) {
    // Sapling ('ps') addresses aren't stored in the regular address list.
    if (addr.startsWith('ps1') || addr.startsWith('ps')) {
      selectedShieldedAddress = addr;
      return;
    }
    selectedShieldedAddress = null;
    super.address = addr;
  }
}
