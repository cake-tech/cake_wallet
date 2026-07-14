import "dart:convert";

import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/currency.dart";

class SolanaBalance extends Balance {
  SolanaBalance(Money balance) : super(balance, balance.copyWith(amount: BigInt.zero));

  factory SolanaBalance.zero(Currency currency) => SolanaBalance(Money.zero(currency));

  static SolanaBalance? fromJSON(String? jsonSource, Currency currency) {
    if (jsonSource == null) return null;

    final decoded = json.decode(jsonSource) as Map;

    try {
      return SolanaBalance(currency.parseAmount(decoded["balance"]));
    } catch (e) {
      return SolanaBalance(Money.zero(currency));
    }
  }

  String toJSON() => json.encode({"balance": available.toString()});
}
