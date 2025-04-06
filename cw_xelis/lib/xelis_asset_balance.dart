import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cw_core/balance.dart';

import 'package:cw_xelis/xelis_formatting.dart';

class XelisAssetBalance extends Balance {
  XelisAssetBalance({
    required this.balance,
    required this.decimals,
  }): super(balance, 0);

  final int balance;
  final int decimals;

  String get formatted {
    final formatter = NumberFormat('0.00##########', 'en_US');
    final value = (BigInt.from(balance) / BigInt.from(10).pow(decimals)).toDouble();
    return formatter.format(value);
  }

  String toJSON() => json.encode({
    'balance': balance.toString(),
    'decimals': decimals,
  });

  static XelisAssetBalance fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;
    return XelisAssetBalance(
      balance: decoded['balance'],
      decimals: decoded['decimals'],
    );
  }

  static XelisAssetBalance zero({int? decimals}) {
    return XelisAssetBalance(
      balance: 0,
      decimals: decimals ?? 8,
    );
  }

  @override
  String get formattedAvailableBalance => formatXelisAmount(balance, decimals: decimals);

  @override
  String get formattedAdditionalBalance => '0';
}
