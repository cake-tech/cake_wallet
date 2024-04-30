import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_core/unspent_transaction_output.dart';

class BitcoinUnspent extends Unspent {
  BitcoinUnspent(BitcoinAddressRecord addressRecord, String hash, int value, int vout)
      : bitcoinAddressRecord = addressRecord,
        super(addressRecord.address, hash, value, vout, null);

  factory BitcoinUnspent.fromJSON(BitcoinAddressRecord address, Map<String, dynamic> json) =>
      BitcoinUnspent(
          address, json['tx_hash'] as String, json['value'] as int, json['tx_pos'] as int);

  final BitcoinAddressRecord bitcoinAddressRecord;
}
