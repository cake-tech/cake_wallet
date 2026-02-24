import 'dart:convert';

import 'package:cw_core/balance.dart';

class SolanaBalance extends Balance {
  SolanaBalance(this.balance, bool isToken) : super(
      int.tryParse(balance.toStringAsFixed(isToken ? 6 : 9).replaceFirst(".", "")) ?? 0,
      int.tryParse(balance.toStringAsFixed(isToken ? 6 : 9).replaceFirst(".", "")) ?? 0);

  final double balance;

  @override
  String get formattedAdditionalBalance => _balanceFormatted();

  @override
  String get formattedAvailableBalance => _balanceFormatted();

  String _balanceFormatted() {
    String stringBalance = balance.toString();
    if (stringBalance.toString().length >= 12) {
      stringBalance = stringBalance.substring(0, 12);
    }
    return stringBalance;
  }

  static SolanaBalance? fromJSON(String? jsonSource, bool isToken) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return SolanaBalance(decoded['balance'], isToken);
    } catch (e) {
      return SolanaBalance(0.0, isToken);
    }
  }

  String toJSON() => json.encode({'balance': balance.toString()});
}
