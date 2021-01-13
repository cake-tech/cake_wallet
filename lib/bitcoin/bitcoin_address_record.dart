import 'dart:convert';
import 'package:quiver/core.dart';

class BitcoinAddressRecord {
  BitcoinAddressRecord(this.address, {this.index});

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(decoded['address'] as String,
        index: decoded['index'] as int);
  }

  @override
  bool operator ==(Object o) =>
      o is BitcoinAddressRecord && address == o.address;

  final String address;
  int index;

  @override
  int get hashCode => address.hashCode;

  String toJSON() => json.encode({'address': address, 'index': index});
}
