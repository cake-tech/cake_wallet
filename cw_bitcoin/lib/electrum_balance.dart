import "dart:convert";

import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";

class ElectrumBalance extends Balance {
  ElectrumBalance({
    required this.confirmed,
    required this.unconfirmed,
    required this.frozen,
    this.secondConfirmed,
    this.secondUnconfirmed,
  }) : super(
          confirmed,
          unconfirmed,
          secondAvailable: secondConfirmed,
          secondUnavailable: secondUnconfirmed,
        );

  CryptoMoney confirmed;
  CryptoMoney unconfirmed;
  CryptoMoney? secondConfirmed;
  CryptoMoney? secondUnconfirmed;

  @override
  CryptoMoney get available => (confirmed + unconfirmed) - frozen;

  @override
  CryptoMoney get unavailable => unconfirmed;

  @override
  CryptoMoney frozen;

  static ElectrumBalance? fromJSON(String? jsonSource, CryptoCurrency currency) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    return ElectrumBalance(
      confirmed: Money.fromInt(decoded["confirmed"] as int? ?? 0, currency),
      unconfirmed: Money.fromInt(decoded["unconfirmed"] as int? ?? 0, currency),
      frozen: Money.fromInt(decoded["frozen"] as int? ?? 0, currency),
      secondConfirmed: Money.fromInt(decoded["secondConfirmed"] as int? ?? 0, currency),
      secondUnconfirmed: Money.fromInt(decoded["secondUnconfirmed"] as int? ?? 0, currency),
    );
  }

  String toJSON() => json.encode({
        "confirmed": confirmed.amount.toInt(),
        "unconfirmed": unavailable.amount.toInt(),
        "frozen": frozen.amount.toInt(),
        "secondConfirmed": secondAvailable?.amount.toInt() ?? 0,
        "secondUnconfirmed": secondUnavailable?.amount.toInt() ?? 0,
      });
}
