import 'package:bitcoin_base/bitcoin_base.dart';

class CoreReceivePageOption {
  static const mainnet = CoreReceivePageOption._('mainnet');
  static const anonPayInvoice = CoreReceivePageOption._('anonPayInvoice');
  static const anonPayDonationLink = CoreReceivePageOption._('anonPayDonationLink');

  const CoreReceivePageOption._(this._value);

  final String _value;
}

const ReceivePageOptions = [
  CoreReceivePageOption.mainnet,
  CoreReceivePageOption.anonPayInvoice,
  CoreReceivePageOption.anonPayDonationLink
];

class BitcoinReceivePageOption extends CoreReceivePageOption {
  static const p2wpkh = BitcoinReceivePageOption._('Segwit (P2WPKH)');
  static const p2tr = BitcoinReceivePageOption._('Taproot (P2TR)');
  static const p2wsh = BitcoinReceivePageOption._('Segwit (P2WSH)');
  static const p2pkh = BitcoinReceivePageOption._('Legacy (P2PKH)');

  const BitcoinReceivePageOption._(String value) : super._(value);

  factory BitcoinReceivePageOption.fromType(BitcoinAddressType type) {
    switch (type) {
      case BitcoinAddressType.p2tr:
        return BitcoinReceivePageOption.p2tr;
      case BitcoinAddressType.p2wsh:
        return BitcoinReceivePageOption.p2wsh;
      case BitcoinAddressType.p2pkh:
        return BitcoinReceivePageOption.p2pkh;
      case BitcoinAddressType.p2wpkh:
      default:
        return BitcoinReceivePageOption.p2wpkh;
    }
  }

  @override
  String toString() {
    return _value;
  }
}

const BitcoinReceivePageOptions = [
  BitcoinReceivePageOption.p2wpkh,
  BitcoinReceivePageOption.p2tr,
  BitcoinReceivePageOption.p2wsh,
  BitcoinReceivePageOption.p2pkh
];
