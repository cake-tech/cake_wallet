import 'package:cw_bitcoin/bitcoin_address_record.dart';

class BitcoinUnspent {
  BitcoinUnspent(this.address, this.hash, this.value, this.vout, {bool? isSilent})
      : isSending = true,
        isFrozen = false,
        note = '',
        isSilent = isSilent ?? false;

  factory BitcoinUnspent.fromJSON(BitcoinAddressRecord address, Map<String, dynamic> json,
          {bool? isSilent}) =>
      BitcoinUnspent(
          address, json['tx_hash'] as String, json['value'] as int, json['tx_pos'] as int,
          isSilent: isSilent);

  final BitcoinAddressRecord address;
  final String hash;
  final int value;
  final int vout;

  bool get isP2wpkh =>
      address.address.startsWith('bc') ||
      // testnet
      address.address.startsWith('tb') ||
      address.address.startsWith('ltc');
  bool isSending;
  bool isFrozen;
  bool isSilent;
  String note;
}
