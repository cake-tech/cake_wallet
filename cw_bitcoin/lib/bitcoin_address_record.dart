import 'dart:convert';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';

class BitcoinAddressRecord {
  BitcoinAddressRecord(this.address,
      {required this.index,
      this.isHidden = false,
      bool isUsed = false,
      this.silentAddressLabel,
      this.silentPaymentTweak,
      this.type})
      : _isUsed = isUsed;

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(decoded['address'] as String,
        index: decoded['index'] as int,
        isHidden: decoded['isHidden'] as bool? ?? false,
        isUsed: decoded['isUsed'] as bool? ?? false,
        silentAddressLabel: decoded['silentAddressLabel'] as String?,
        silentPaymentTweak: decoded['silentPaymentTweak'] as String?,
        type: decoded['type'] != null && decoded['type'] != ''
            ? AddressType.values.firstWhere((type) => type.toString() == decoded['type'] as String)
            : null);
  }

  @override
  bool operator ==(Object o) => o is BitcoinAddressRecord && address == o.address;

  final String address;
  final bool isHidden;
  final String? silentAddressLabel;
  final String? silentPaymentTweak;
  final int index;
  bool get isUsed => _isUsed;

  @override
  int get hashCode => address.hashCode;

  bool _isUsed;

  void setAsUsed() => _isUsed = true;

  AddressType? type;

  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'isUsed': isUsed,
        'silentAddressLabel': silentAddressLabel,
        'silentPaymentTweak': silentPaymentTweak,
        'type': type?.toString() ?? '',
      });
}
