import 'dart:convert';

class BitcoinAddressRecord {
  BitcoinAddressRecord(this.address, {this.label, this.index});

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(decoded['address'] as String,
        label: decoded['label'] as String, index: decoded['index'] as int);
  }

  final String address;
  int index;
  String label;

  String toJSON() =>
      json.encode({'label': label, 'address': address, 'index': index});
}
