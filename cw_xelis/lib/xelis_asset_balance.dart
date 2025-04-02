import 'dart:convert';
import 'package:intl/intl.dart';

class XelisAssetBalance {
  XelisAssetBalance({
    required this.balance,
    required this.decimals,
  });

  final BigInt balance;
  final int decimals;

  String get formatted {
    final formatter = NumberFormat('0.00##########', 'en_US');
    final value = (balance / BigInt.from(10).pow(decimals)).toDouble();
    return formatter.format(value);
  }

  String toJson() => json.encode({
    'balance': balance.toString(),
    'decimals': decimals,
  });

  static XelisAssetBalance fromJson(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;
    return XelisAssetBalance(
      balance: BigInt.parse(decoded['balance']),
      decimals: decoded['decimals'],
    );
  }
}
