import "dart:convert";

import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";

class EVMChainERC20Balance extends Balance {
  EVMChainERC20Balance(CryptoMoney balance) : super(balance, Money.zero(balance.currency));

  String toJSON() => json.encode({"balanceInWei": available.amount.toString()});

  static EVMChainERC20Balance? fromJSON(String? jsonSource, CryptoCurrency currency) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return EVMChainERC20Balance(Money(BigInt.parse(decoded["balanceInWei"] as String), currency));
    } catch (e) {
      return EVMChainERC20Balance(Money.zero(currency));
    }
  }
}
