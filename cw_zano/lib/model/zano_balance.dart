import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/currency.dart';

class ZanoBalance extends Balance {
  final Money total;
  final Money unlocked;

  ZanoBalance({required this.total, required this.unlocked}) : super(unlocked, (total - unlocked));

  ZanoBalance.empty(Currency currency)
      : total = Money.zero(currency),
        unlocked = Money.zero(currency),
        super(Money.zero(currency), Money.zero(currency));
}
