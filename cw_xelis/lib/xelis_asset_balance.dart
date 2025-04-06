import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cw_core/balance.dart';

import 'package:cw_xelis/xelis_formatting.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;

class XelisAssetBalance extends Balance {
  XelisAssetBalance({
    required this.balance,
    required this.decimals,
    this.asset = xelis_sdk.xelisAsset,
    this.symbol = "XEL"
  }): super(balance, 0);

  final int balance;
  final int decimals;
  final String asset;
  final String symbol;

  String get formatted {
    final formatter = NumberFormat('0.00##########', 'en_US');
    final value = (BigInt.from(balance) / BigInt.from(10).pow(decimals)).toDouble();
    return formatter.format(value);
  }

  String toJSON() => json.encode({
    'balance': balance.toString(),
    'decimals': decimals,
    'asset': asset,
    'symbol': symbol
  });

  static XelisAssetBalance fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;
    return XelisAssetBalance(
      balance: decoded['balance'],
      decimals: decoded['decimals'],
      asset: decoded['asset'],
      symbol: decoded['symbol'],
    );
  }

  static XelisAssetBalance zero({int? decimals, String? asset, String? symbol}) {
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
