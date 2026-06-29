import 'package:cw_core/balance.dart';
import 'package:cw_core/nerva_amount_format.dart';

class NervaBalance extends Balance {
  NervaBalance({required this.fullBalance, required this.unlockedBalance, this.frozenBalance = 0})
      : formattedFrozenBalance = nervaAmountToString(amount: frozenBalance),
        super.fromInt(unlockedBalance, fullBalance - unlockedBalance, frozen: frozenBalance);

  final int fullBalance;
  final int unlockedBalance;
  final int frozenBalance;
  final String formattedFrozenBalance;

  @override
  String get formattedUnAvailableBalance =>
      formattedFrozenBalance == '0.0' ? '' : formattedFrozenBalance;
}
