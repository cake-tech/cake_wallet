import 'package:cw_core/balance.dart';
import 'package:cw_core/salvium_amount_format.dart';

class SalviumBalance extends Balance {
  SalviumBalance(
      {required this.fullBalance,
      required this.unlockedBalance,
      this.frozenBalance = 0})
      : formattedFullBalance = salviumAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            salviumAmountToString(amount: unlockedBalance - frozenBalance),
        formattedLockedBalance = salviumAmountToString(
            amount: frozenBalance + fullBalance - unlockedBalance),
        super(unlockedBalance, fullBalance);

  SalviumBalance.fromString(
      {required this.formattedFullBalance,
      required this.formattedUnlockedBalance,
      this.formattedLockedBalance = '0.0'})
      : fullBalance = salviumParseAmount(amount: formattedFullBalance),
        unlockedBalance = salviumParseAmount(amount: formattedUnlockedBalance),
        frozenBalance = salviumParseAmount(amount: formattedLockedBalance),
        super(salviumParseAmount(amount: formattedUnlockedBalance),
            salviumParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final int frozenBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;
  final String formattedLockedBalance;

  @override
  String get formattedUnAvailableBalance =>
      formattedLockedBalance == '0.0' ? '' : formattedLockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}
