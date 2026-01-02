import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/lightning/lightning_addres_type.dart';
import 'package:cw_core/receive_page_option.dart';

class BitcoinReceivePageOption implements ReceivePageOption {
  static const p2wpkh = BitcoinReceivePageOption._('Standard',
      description: "Default (P2WPKH)",
      iconPath: "assets/new-ui/address-type-picker-icons/btc_standard.svg",
      isCommon: true);
  static const p2sh = BitcoinReceivePageOption._('Segwit-Compatible',
      description: "P2SK", iconPath: "assets/new-ui/address-type-picker-icons/segwit.svg");
  static const p2tr = BitcoinReceivePageOption._('Taproot',
      description: "P2TR", iconPath: "assets/new-ui/address-type-picker-icons/taproot.svg");
  static const p2wsh = BitcoinReceivePageOption._('Segwit',
      description: "P2WSH", iconPath: "assets/new-ui/address-type-picker-icons/segwit.svg");
  static const p2pkh = BitcoinReceivePageOption._('Legacy',
      description: "P2PKH", iconPath: "assets/new-ui/address-type-picker-icons/legacy.svg");
  static const mweb = BitcoinReceivePageOption._('MWEB');

  static const silent_payments = BitcoinReceivePageOption._('Silent Payments',
      description: "Privacy-preserving static address",
      iconPath: "assets/new-ui/address-type-picker-icons/silent.svg",
      isCommon: true);
  static const lightning = BitcoinReceivePageOption._('Lightning',
      description: "Instant, low fee payments",
      iconPath: "assets/new-ui/address-type-picker-icons/btc_lightning.svg",
      isCommon: true);

  const BitcoinReceivePageOption._(this.value,
      {this.iconPath, this.description, this.isCommon = false});

  final String value;
  final String? iconPath;
  final String? description;
  final bool isCommon;

  String toString() {
    return value;
  }

  static const all = [
    BitcoinReceivePageOption.lightning,
    BitcoinReceivePageOption.silent_payments,
    BitcoinReceivePageOption.p2wpkh,
    BitcoinReceivePageOption.p2tr,
    BitcoinReceivePageOption.p2wsh,
    BitcoinReceivePageOption.p2sh,
    BitcoinReceivePageOption.p2pkh
  ];

  static const allViewOnly = [
    BitcoinReceivePageOption.p2wpkh,
    // TODO: uncomment this after we properly derive keys and not use m/84 for
    // all of them (as this breaks cupcake)
    // BitcoinReceivePageOption.p2tr,
    // BitcoinReceivePageOption.p2wsh,
    // BitcoinReceivePageOption.p2sh,
    // BitcoinReceivePageOption.p2pkh
  ];

  static const allLitecoin = [
    BitcoinReceivePageOption.p2wpkh,
    BitcoinReceivePageOption.mweb,
  ];

  BitcoinAddressType toType() {
    switch (this) {
      case BitcoinReceivePageOption.p2tr:
        return SegwitAddresType.p2tr;
      case BitcoinReceivePageOption.p2wsh:
        return SegwitAddresType.p2wsh;
      case BitcoinReceivePageOption.p2pkh:
        return P2pkhAddressType.p2pkh;
      case BitcoinReceivePageOption.p2sh:
        return P2shAddressType.p2wpkhInP2sh;
      case BitcoinReceivePageOption.silent_payments:
        return SilentPaymentsAddresType.p2sp;
      case BitcoinReceivePageOption.lightning:
        return LightningAddressType.p2l;
      case BitcoinReceivePageOption.mweb:
        return SegwitAddresType.mweb;
      case BitcoinReceivePageOption.p2wpkh:
      default:
        return SegwitAddresType.p2wpkh;
    }
  }

  factory BitcoinReceivePageOption.fromType(BitcoinAddressType type) {
    switch (type) {
      case SegwitAddresType.p2tr:
        return BitcoinReceivePageOption.p2tr;
      case SegwitAddresType.p2wsh:
        return BitcoinReceivePageOption.p2wsh;
      case SegwitAddresType.mweb:
        return BitcoinReceivePageOption.mweb;
      case P2pkhAddressType.p2pkh:
        return BitcoinReceivePageOption.p2pkh;
      case P2shAddressType.p2wpkhInP2sh:
        return BitcoinReceivePageOption.p2sh;
      case SilentPaymentsAddresType.p2sp:
        return BitcoinReceivePageOption.silent_payments;
      case LightningAddressType.p2l:
        return BitcoinReceivePageOption.lightning;
      case SegwitAddresType.p2wpkh:
      default:
        return BitcoinReceivePageOption.p2wpkh;
    }
  }
}
