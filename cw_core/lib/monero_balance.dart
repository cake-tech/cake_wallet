import 'package:cw_core/balance.dart';
import 'package:cw_core/monero_amount_format.dart';

class MoneroBalance extends Balance {
  MoneroBalance({required this.fullBalance, required this.unlockedBalance, this.frozenBalance = 0})
      : formattedFrozenBalance = moneroAmountToString(amount: frozenBalance),
        super(unlockedBalance, fullBalance, frozen: frozenBalance);

  final int fullBalance;
  final int unlockedBalance;
  final int frozenBalance;
  final String formattedFrozenBalance;

  @override
  String get formattedUnAvailableBalance =>
      formattedFrozenBalance == '0.0' ? '' : formattedFrozenBalance;
}
