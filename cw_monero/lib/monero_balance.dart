import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';

class MoneroBalance extends Balance {
  MoneroBalance({
    required this.fullBalance,
    required Money unlockedBalance,
    Money? frozen,
  }) : super(
          unlockedBalance,
          fullBalance - unlockedBalance,
          frozen: frozen ?? Money.zero(CryptoCurrency.xmr),
        );

  final Money fullBalance;
}
