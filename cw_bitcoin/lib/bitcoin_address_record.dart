import 'dart:convert';
import 'package:bitbox/bitbox.dart' as bitbox;

import 'package:bitcoin_base/bitcoin_base.dart';

class BitcoinAddressRecord {
  BitcoinAddressRecord(
    this.address, {
    required this.index,
    this.isHidden = false,
    int txCount = 0,
    int balance = 0,
    String name = '',
    bool isUsed = false,
    required this.type,
  })  : _txCount = txCount,
        _balance = balance,
        _name = name,
        _isUsed = isUsed;

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(
      decoded['address'] as String,
      index: decoded['index'] as int,
      isHidden: decoded['isHidden'] as bool? ?? false,
      isUsed: decoded['isUsed'] as bool? ?? false,
      txCount: decoded['txCount'] as int? ?? 0,
      name: decoded['name'] as String? ?? '',
      balance: decoded['balance'] as int? ?? 0,
      type: decoded['type'] != null && decoded['type'] != ''
          ? BitcoinAddressType.values
              .firstWhere((type) => type.toString() == decoded['type'] as String)
          : SegwitAddresType.p2wpkh,
    );
  }

  @override
  bool operator ==(Object o) => o is BitcoinAddressRecord && address == o.address;

  final String address;
  final bool isHidden;
  final int index;
  int _txCount;
  int _balance;
  String _name;
  bool _isUsed;

  int get txCount => _txCount;

  String get name => _name;

  int get balance => _balance;

  set txCount(int value) => _txCount = value;

  set balance(int value) => _balance = value;

  bool get isUsed => _isUsed;

  void setAsUsed() => _isUsed = true;
  void setNewName(String label) => _name = label;

  @override
  int get hashCode => address.hashCode;

  String get cashAddr => bitbox.Address.toCashAddress(address);

  BitcoinAddressType type;

  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance,
        'type': type.toString(),
      });
}
