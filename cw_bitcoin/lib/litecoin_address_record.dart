import 'dart:convert';
import 'package:cw_bitcoin/bitcoin_address_record.dart';

import 'package:bitcoin_base_old/bitcoin_base.dart';

class LitecoinAddressRecord extends BitcoinAddressRecord {
  LitecoinAddressRecord(
    super.address, {
    required super.index,
    super.isHidden = false,
    super.txCount = 0,
    super.balance = 0,
    super.name = '',
    super.isUsed = false,
    required this.type,
    String? scriptHash,
    required this.network,
  }) : scriptHash = scriptHash ??
            (network != null ? BitcoinAddressUtils.scriptHash(address, network: network) : null);

  factory LitecoinAddressRecord.fromJSON(String jsonSource, {BasedUtxoNetwork? network}) {
    final decoded = json.decode(jsonSource) as Map;

    return LitecoinAddressRecord(
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

  final BitcoinAddressType type;
  final BasedUtxoNetwork? network;

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
