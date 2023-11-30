import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';

class BitcoinUnspent extends Unspent {
  BitcoinUnspent(BitcoinAddressRecord addressRecord, String hash, int value, int vout,
      {this.silentPaymentTweak, this.type})
      : bitcoinAddressRecord = addressRecord,
        super(addressRecord.address, hash, value, vout, null);

  factory BitcoinUnspent.fromJSON(BitcoinAddressRecord address, Map<String, dynamic> json) =>
      BitcoinUnspent(
        address,
        json['tx_hash'] as String,
        json['value'] as int,
        json['tx_pos'] as int,
        silentPaymentTweak: json['silent_payment_tweak'] as String?,
        type: json['type'] == null ? null : AddressType.values[json['type'] as int],
      );

  final BitcoinAddressRecord bitcoinAddressRecord;
  String? silentPaymentTweak;
  AddressType? type;
}
