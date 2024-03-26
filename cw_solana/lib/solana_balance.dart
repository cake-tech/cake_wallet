import 'dart:convert';

import 'package:cw_core/balance.dart';

class SolanaBalance extends Balance {
  SolanaBalance(this.balance) : super(balance.toInt(), balance.toInt());

  final double balance;

  @override
  String get formattedAdditionalBalance => _balanceFormatted();

  @override
  String get formattedAvailableBalance => _balanceFormatted();

  String _balanceFormatted() {
    String stringBalance = balance.toString();
    if (stringBalance.toString().length >= 6) {
      stringBalance = stringBalance.substring(0, 6);
    }
    return stringBalance;
  }

  static SolanaBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return SolanaBalance(decoded['balance']);
    } catch (e) {
      return SolanaBalance(0.0);
    }
  }

  String toJSON() => json.encode({'balance': balance.toString()});
}
