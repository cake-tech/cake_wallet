import 'dart:convert';

class BitcoinAddressRecord {
  BitcoinAddressRecord(this.address, {this.index});

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(decoded['address'] as String,
        index: decoded['index'] as int);
  }

  final String address;
  int index;

  String toJSON() => json.encode({'address': address, 'index': index});
}
