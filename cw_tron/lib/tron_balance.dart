import 'dart:convert';

import 'package:cw_core/balance.dart';
import 'package:on_chain/on_chain.dart';

class TronBalance extends Balance {
  TronBalance(this.balance) : super(balance.toInt(), balance.toInt());

  final BigInt balance;

  @override
  String get formattedAdditionalBalance => TronHelper.fromSun(balance);

  @override
  String get formattedAvailableBalance => TronHelper.fromSun(balance);

  String toJSON() => json.encode({
        'balance': balance.toString(),
      });

  static TronBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return TronBalance(BigInt.parse(decoded['balance']));
    } catch (e) {
      return TronBalance(BigInt.zero);
    }
  }
}
