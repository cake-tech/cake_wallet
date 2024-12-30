import 'package:cw_core/balance.dart';
import 'package:cw_core/wownero_amount_format.dart';

class WowneroBalance extends Balance {
  WowneroBalance({required this.fullBalance, required this.unlockedBalance, this.frozenBalance = 0})
      : formattedUnconfirmedBalance = wowneroAmountToString(amount: fullBalance - unlockedBalance),
        formattedUnlockedBalance = wowneroAmountToString(amount: unlockedBalance),
        formattedFrozenBalance =
        wowneroAmountToString(amount: frozenBalance),
        super(unlockedBalance, fullBalance);

  final int fullBalance;
  final int unlockedBalance;
  final int frozenBalance;
  final String formattedUnconfirmedBalance;
  final String formattedUnlockedBalance;
  final String formattedFrozenBalance;

  @override
  String get formattedUnAvailableBalance =>
      formattedFrozenBalance == '0.0' ? '' : formattedFrozenBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedUnconfirmedBalance;
}