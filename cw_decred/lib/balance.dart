import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';

class DecredBalance extends Balance {
  DecredBalance({required Money confirmed, required Money unconfirmed, required Money frozen})
      : super(confirmed, unconfirmed, frozen: frozen);

  factory DecredBalance.zero() => DecredBalance(
      confirmed: Money.zero(CryptoCurrency.dcr),
      unconfirmed: Money.zero(CryptoCurrency.dcr),
      frozen: Money.zero(CryptoCurrency.dcr));

  @override
  Money get available => super.available - (frozen ?? Money.zero(CryptoCurrency.dcr));
}
