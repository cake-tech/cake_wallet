import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';

class ZcashBalance extends Balance {
  ZcashBalance(super.available, super.unavailable, {required super.frozen});

  factory ZcashBalance.zero() => ZcashBalance(
    Money.zero(CryptoCurrency.zec),
    Money.zero(CryptoCurrency.zec),
    frozen: Money.zero(CryptoCurrency.zec),
  );
}
