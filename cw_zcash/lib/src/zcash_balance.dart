import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';

class ZcashBalance extends Balance {
  ZcashBalance({required this.confirmed, required this.unconfirmed, required final Money frozen})
    : super(confirmed, unconfirmed, frozen: frozen);

  factory ZcashBalance.zero() => ZcashBalance(
    confirmed: Money.zero(CryptoCurrency.zec),
    unconfirmed: Money.zero(CryptoCurrency.zec),
    frozen: Money.zero(CryptoCurrency.zec),
  );

  final Money confirmed;
  final Money unconfirmed;
}
