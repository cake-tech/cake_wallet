import 'dart:convert';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/currency.dart';

class TronBalance extends Balance {
  TronBalance(this.balance) : super(balance, balance);

  final Money balance;

  String toJSON() => json.encode({'balance': balance.amount.toString()});

  static TronBalance? fromJSON(String? jsonSource, Currency currency) {
    if (jsonSource == null) return null;

    final decoded = json.decode(jsonSource) as Map;

    try {
      return TronBalance(Money(BigInt.parse(decoded['balance']), currency));
    } catch (e) {
      return TronBalance(Money.zero(currency));
    }
  }
}
