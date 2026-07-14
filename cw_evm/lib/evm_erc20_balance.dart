import "dart:convert";

import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/currency.dart";

class EVMChainERC20Balance extends Balance {
  EVMChainERC20Balance(Money balance) : super(balance, Money.zero(balance.currency));

  String toJSON() => json.encode({"balanceInWei": available.amount.toString()});

  static EVMChainERC20Balance? fromJSON(String? jsonSource, Currency currency) {
    if (jsonSource == null) return null;

    final decoded = json.decode(jsonSource) as Map;

    try {
      return EVMChainERC20Balance(Money(BigInt.parse(decoded["balanceInWei"]), currency));
    } catch (e) {
      return EVMChainERC20Balance(Money.zero(currency));
    }
  }
}
