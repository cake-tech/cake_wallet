import 'dart:convert';

import 'package:cw_core/balance.dart';

class StarknetBalance extends Balance {
  StarknetBalance(this.balance)
      : super(
          BigInt.from(int.tryParse(balance.toStringAsFixed(18).replaceFirst(".", "")) ?? 0),
          BigInt.from(int.tryParse(balance.toStringAsFixed(18).replaceFirst(".", "")) ?? 0),
        );

  final double balance;

  String get formattedAdditionalBalance => _balanceFormatted();

  String get formattedAvailableBalance => _balanceFormatted();

  String _balanceFormatted() {
    String stringBalance = balance.toString();
    if (stringBalance.length >= 12) {
      stringBalance = stringBalance.substring(0, 12);
    }
    return stringBalance;
  }

  static StarknetBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return StarknetBalance(double.parse(decoded['balance'].toString()));
    } catch (e) {
      return StarknetBalance(0.0);
    }
  }

  String toJSON() => json.encode({'balance': balance.toString()});
}
