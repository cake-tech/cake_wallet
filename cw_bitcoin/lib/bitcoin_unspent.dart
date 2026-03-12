import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_core/unspent_transaction_output.dart';

class BitcoinUnspent extends Unspent {
  BitcoinUnspent(BaseBitcoinAddressRecord addressRecord, String hash, int value, int vout)
      : bitcoinAddressRecord = addressRecord,
        super(addressRecord.address, hash, value, vout, null);

  factory BitcoinUnspent.fromJSON(BaseBitcoinAddressRecord? address, Map<String, dynamic> json) =>
      BitcoinUnspent(
        address ?? BitcoinAddressRecord.fromJSON(json['address_record'].toString()),
        json['tx_hash'] as String,
        json['value'] as int,
        json['tx_pos'] as int,
      );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'address_record': bitcoinAddressRecord.toJSON(),
      'tx_hash': hash,
      'value': value,
      'tx_pos': vout,
    };
    return json;
  }

  final BaseBitcoinAddressRecord bitcoinAddressRecord;
  bool? isPegOut;
}

class BitcoinSilentPaymentsUnspent extends BitcoinUnspent {
  BitcoinSilentPaymentsUnspent(
    BitcoinSilentPaymentAddressRecord addressRecord,
    String hash,
    int value,
    int vout, {
    required this.silentPaymentTweak,
    required this.silentPaymentLabel,
  }) : super(addressRecord, hash, value, vout);

  @override
  factory BitcoinSilentPaymentsUnspent.fromJSON(
          BitcoinSilentPaymentAddressRecord? address, Map<String, dynamic> json) =>
      BitcoinSilentPaymentsUnspent(
        address ?? BitcoinSilentPaymentAddressRecord.fromJSON(json['address_record'].toString()),
        json['tx_hash'] as String,
        json['value'] as int,
        json['tx_pos'] as int,
        silentPaymentTweak: json['silent_payment_tweak'] as String?,
        silentPaymentLabel: json['silent_payment_label'] as String?,
      );

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'address_record': bitcoinAddressRecord.toJSON(),
      'tx_hash': hash,
      'value': value,
      'tx_pos': vout,
      'silent_payment_tweak': silentPaymentTweak,
      'silent_payment_label': silentPaymentLabel,
    };
    return json;
  }

  String? silentPaymentTweak;
  String? silentPaymentLabel;
}
