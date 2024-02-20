import 'dart:convert';
import 'package:bitbox/bitbox.dart' as bitbox;

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
    String? scriptHash,
    required this.network,
    this.silentPaymentTweak,
  })  : _txCount = txCount,
        _balance = balance,
        _name = name,
        _isUsed = isUsed;

  factory BitcoinAddressRecord.fromJSON(String jsonSource, {BasedUtxoNetwork? network}) {
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
      scriptHash: decoded['scriptHash'] as String?,
      network: (decoded['network'] as String?) == null
          ? network
          : BasedUtxoNetwork.fromName(decoded['network'] as String),
      silentPaymentTweak: decoded['silentPaymentTweak'] as String?,
    );
  }

  final String address;
  bool isHidden;
  final int index;
  int _txCount;
  int _balance;
  String _name;
  bool _isUsed;
  String? scriptHash;
  BasedUtxoNetwork? network;
  final String? silentPaymentTweak;

  int get txCount => _txCount;

  String get name => _name;

  int get balance => _balance;

  set txCount(int value) => _txCount = value;

  set balance(int value) => _balance = value;

  bool get isUsed => _isUsed;

  void setAsUsed() => _isUsed = true;
  void setNewName(String label) => _name = label;

  @override
  bool operator ==(Object o) => o is BitcoinAddressRecord && address == o.address;

  @override
  int get hashCode => address.hashCode;

  String get cashAddr => bitbox.Address.toCashAddress(address);

  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'txCount': txCount,
        'name': name,
        'isUsed': isUsed,
        'balance': balance,
        'type': type.toString(),
        'scriptHash': scriptHash,
        'network': network?.value,
        'silentPaymentTweak': silentPaymentTweak,
      });
}
