import 'dart:convert';
import 'package:mobx/mobx.dart';

import 'package:bitcoin_base/bitcoin_base.dart';

abstract class BaseBitcoinAddressRecord {
  BaseBitcoinAddressRecord(
    this.address, {
    required this.index,
    this.isHidden = false,
    int txCount = 0,
    int balance = 0,
    String name = '',
    bool isUsed = false,
    required this.type,
    required this.network,
  })  : _txCount = txCount,
        _balance = balance,
        _name = name,
        _isUsed = Observable(isUsed);

  @override
  bool operator ==(Object o) => o is BaseBitcoinAddressRecord && address == o.address;

  final String address;
  bool isHidden;
  final int index;
  int _txCount;
  int _balance;
  String _name;
  final Observable<bool> _isUsed;
  BasedUtxoNetwork? network;

  int get txCount => _txCount;

  String get name => _name;

  int get balance => _balance;

  set txCount(int value) => _txCount = value;

  set balance(int value) => _balance = value;

  bool get isUsed => _isUsed.value;

  void setAsUsed() => _isUsed.value = true;
  void setNewName(String label) => _name = label;

  int get hashCode => address.hashCode;

  BitcoinAddressType type;

  String toJSON();
}

class BitcoinAddressRecord extends BaseBitcoinAddressRecord {
  BitcoinAddressRecord(
    super.address, {
    required super.index,
    super.isHidden = false,
    super.txCount = 0,
    super.balance = 0,
    super.name = '',
    super.isUsed = false,
    required super.type,
    String? scriptHash,
    required super.network,
  }) : scriptHash = scriptHash ??
            (network != null ? BitcoinAddressUtils.scriptHash(address, network: network) : null);

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
      network: network,
    );
  }

  String? scriptHash;

  String getScriptHash(BasedUtxoNetwork network) {
    if (scriptHash != null) return scriptHash!;
    scriptHash = BitcoinAddressUtils.scriptHash(address, network: network);
    return scriptHash!;
  }

  @override
  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance,
        'type': type.toString(),
        'scriptHash': scriptHash,
      });
}

class BitcoinSilentPaymentAddressRecord extends BaseBitcoinAddressRecord {
  BitcoinSilentPaymentAddressRecord(
    super.address, {
    required super.index,
    super.isHidden = false,
    super.txCount = 0,
    super.balance = 0,
    super.name = '',
    super.isUsed = false,
    required this.silentPaymentTweak,
    required super.network,
    required super.type,
  }) : super();

  factory BitcoinSilentPaymentAddressRecord.fromJSON(String jsonSource,
      {BasedUtxoNetwork? network}) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinSilentPaymentAddressRecord(
      decoded['address'] as String,
      index: decoded['index'] as int,
      isHidden: decoded['isHidden'] as bool? ?? false,
      isUsed: decoded['isUsed'] as bool? ?? false,
      txCount: decoded['txCount'] as int? ?? 0,
      name: decoded['name'] as String? ?? '',
      balance: decoded['balance'] as int? ?? 0,
      network: (decoded['network'] as String?) == null
          ? network
          : BasedUtxoNetwork.fromName(decoded['network'] as String),
      silentPaymentTweak: decoded['silent_payment_tweak'] as String?,
      type: decoded['type'] != null && decoded['type'] != ''
          ? BitcoinAddressType.values
              .firstWhere((type) => type.toString() == decoded['type'] as String)
          : SilentPaymentsAddresType.p2sp,
    );
  }

  final String? silentPaymentTweak;

  @override
  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance,
        'type': type.toString(),
        'network': network?.value,
        'silent_payment_tweak': silentPaymentTweak,
      });
}
