import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:bitcoin_base/bitcoin_base.dart';

class BitcoinUnspent extends Unspent {
  BitcoinUnspent(BaseBitcoinAddressRecord addressRecord, String hash, int value, int vout)
      : bitcoinAddressRecord = addressRecord,
        super(addressRecord.address, hash, value, vout, null);

  factory BitcoinUnspent.fromUTXO(BaseBitcoinAddressRecord address, ElectrumUtxo utxo) =>
      BitcoinUnspent(address, utxo.txId, utxo.value.toInt(), utxo.vout);

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

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is BitcoinUnspent && hash == o.hash && vout == o.vout;
  }

  @override
  int get hashCode => Object.hash(hash, vout);
}
