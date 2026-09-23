import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";

class ZanoBalance extends Balance {
  ZanoBalance({required this.total, required this.unlocked}) : super(unlocked, total - unlocked);

  ZanoBalance.empty(CryptoCurrency currency)
      : total = Money.zero(currency),
        unlocked = Money.zero(currency),
        super(Money.zero(currency), Money.zero(currency));

  final CryptoMoney total;
  final CryptoMoney unlocked;
}
