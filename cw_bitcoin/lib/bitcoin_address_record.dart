import 'dart:convert';

class BitcoinAddressRecord {
  BitcoinAddressRecord(
    this.address, {
    required this.index,
    this.isHidden = false,
    int txCount = 0,
    int balance = 0,
    bool isUsed = false,
  })  : _txCount = txCount,
        _balance = balance,
        _isUsed = isUsed;

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(decoded['address'] as String,
        index: decoded['index'] as int,
        isHidden: decoded['isHidden'] as bool? ?? false,
        isUsed: decoded['isUsed'] as bool? ?? false,
        txCount: decoded['txCount'] as int? ?? 0,
        balance: decoded['balance'] as int? ?? 0);
  }

  final String address;
  final bool isHidden;
  final int index;
  int _txCount;
  int _balance;
  bool _isUsed;

  int get txCount => _txCount;

  int get balance => _balance;

  set txCount(int value) => _txCount = value;

  set balance(int value) => _balance = value;

  bool get isUsed => _isUsed;

  void setAsUsed() => _isUsed = true;

  @override
  bool operator ==(Object o) => o is BitcoinAddressRecord && address == o.address;

  @override
  int get hashCode => address.hashCode;

  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'txCount': txCount,
        'isUsed': isUsed,
        'balance': balance,
      });
}
