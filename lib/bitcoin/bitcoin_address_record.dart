import 'dart:convert';

class BitcoinAddressRecord {
  BitcoinAddressRecord(this.address, {this.label});

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(decoded['address'] as String,
        label: decoded['label'] as String);
  }

  final String address;
  String label;

  String toJSON() => json.encode({'label': label, 'address': address});
}
