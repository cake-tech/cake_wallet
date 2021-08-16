import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';

class BitcoinUnspent {
  BitcoinUnspent(this.address, this.hash, this.value, this.vout)
      : isSending = true,
        isFrozen = false,
        note = '';

  factory BitcoinUnspent.fromJSON(
          BitcoinAddressRecord address, Map<String, dynamic> json) =>
      BitcoinUnspent(address, json['tx_hash'] as String, json['value'] as int,
          json['tx_pos'] as int);

  final BitcoinAddressRecord address;
  final String hash;
  final int value;
  final int vout;

  bool get isP2wpkh =>
      address.address.startsWith('bc') || address.address.startsWith('ltc');
  bool isSending;
  bool isFrozen;
  String note;
}
