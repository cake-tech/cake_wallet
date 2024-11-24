import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:bitcoin_base/bitcoin_base.dart';

class BitcoinUnspent extends Unspent {
  BitcoinUnspent(BaseBitcoinAddressRecord addressRecord, String hash, int value, int vout)
      : bitcoinAddressRecord = addressRecord,
        super(addressRecord.address, hash, value, vout, null);

  factory BitcoinUnspent.fromUTXO(BaseBitcoinAddressRecord address, ElectrumUtxo utxo) =>
      BitcoinUnspent(address, utxo.txId, utxo.value.toInt(), utxo.vout);

  factory BitcoinUnspent.fromJSON(BaseBitcoinAddressRecord? address, Map<String, dynamic> json) {
    final addressType = json['address_runtimetype'] as String?;
    final addressRecord = json['address_record'].toString();

    return BitcoinUnspent(
      address ??
          (addressType == null
              ? BitcoinAddressRecord.fromJSON(addressRecord)
              : addressType.contains("SP")
                  ? BitcoinReceivedSPAddressRecord.fromJSON(addressRecord)
                  : BitcoinSilentPaymentAddressRecord.fromJSON(addressRecord)),
      json['tx_hash'] as String,
      int.parse(json['value'].toString()),
      int.parse(json['tx_pos'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'address_record': bitcoinAddressRecord.toJSON(),
      'address_runtimetype': bitcoinAddressRecord.runtimeType.toString(),
      'tx_hash': hash,
      'value': value,
      'tx_pos': vout,
    };
    return json;
  }

  final BaseBitcoinAddressRecord bitcoinAddressRecord;

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is BitcoinUnspent && hash == o.hash && vout == o.vout;
  }

  @override
  int get hashCode => Object.hash(hash, vout);
}
