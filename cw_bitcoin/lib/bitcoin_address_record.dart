import 'dart:convert';

class BitcoinAddressRecord {
  BitcoinAddressRecord(this.address, {this.index, bool isHidden})
      : _isHidden = isHidden;

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(decoded['address'] as String,
        index: decoded['index'] as int, isHidden: decoded['isHidden'] as bool);
  }

  @override
  bool operator ==(Object o) =>
      o is BitcoinAddressRecord && address == o.address;

  final String address;
  bool get isHidden => _isHidden ?? false;
  int index;
  final bool _isHidden;

  @override
  int get hashCode => address.hashCode;

  String toJSON() =>
      json.encode({'address': address, 'index': index, 'isHidden': isHidden});
}
