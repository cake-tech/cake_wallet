import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';

class NanoBalance extends Balance {
  final Money currentBalance;
  final Money receivableBalance;

  NanoBalance({required this.currentBalance, required this.receivableBalance})
      : super(currentBalance, receivableBalance);

  factory NanoBalance.fromRawString({
    required String currentBalance,
    required String receivableBalance,
  }) =>
      NanoBalance(
        currentBalance:
            Money.tryParse(currentBalance, CryptoCurrency.nano) ?? Money.zero(CryptoCurrency.nano),
        receivableBalance: Money.tryParse(receivableBalance, CryptoCurrency.nano) ??
            Money.zero(CryptoCurrency.nano),
      );
}
