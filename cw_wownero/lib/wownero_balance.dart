import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";

class WowneroBalance extends Balance {
  WowneroBalance({
    required this.fullBalance,
    required CryptoMoney unlockedBalance,
    CryptoMoney? frozen,
  }) : super(
          unlockedBalance,
          fullBalance - unlockedBalance,
          frozen: frozen ?? Money.zero(CryptoCurrency.wow),
        );

  final CryptoMoney fullBalance;
}
