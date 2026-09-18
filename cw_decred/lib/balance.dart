import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";

class DecredBalance extends Balance {
  DecredBalance({
    required CryptoMoney confirmed,
    required CryptoMoney unconfirmed,
    required CryptoMoney frozen,
  }) : super(confirmed, unconfirmed, frozen: frozen);

  factory DecredBalance.zero() => DecredBalance(
      confirmed: Money.zero(CryptoCurrency.dcr),
      unconfirmed: Money.zero(CryptoCurrency.dcr),
      frozen: Money.zero(CryptoCurrency.dcr));

  @override
  CryptoMoney get available => super.available - (frozen ?? Money.zero(CryptoCurrency.dcr));
}
