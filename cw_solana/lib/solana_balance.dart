import "dart:convert";

import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";

class SolanaBalance extends Balance {
  SolanaBalance(CryptoMoney balance) : super(balance, balance.copyWith(amount: BigInt.zero));

  factory SolanaBalance.zero(CryptoCurrency currency) => SolanaBalance(Money.zero(currency));

  static SolanaBalance? fromJSON(String? jsonSource, CryptoCurrency currency) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return SolanaBalance(currency.parseAmount(decoded["balance"] as String));
    } catch (e) {
      return SolanaBalance(Money.zero(currency));
    }
  }

  String toJSON() => json.encode({"balance": available.toString()});
}
