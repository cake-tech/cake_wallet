import 'package:cw_core/balance.dart';
import 'package:cw_core/wownero_amount_format.dart';

class WowneroBalance extends Balance {
  WowneroBalance({required this.fullBalance, required this.unlockedBalance, this.frozenBalance = 0})
      : formattedFullBalance = wowneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance = wowneroAmountToString(amount: unlockedBalance - frozenBalance),
        formattedLockedBalance =
        wowneroAmountToString(amount: frozenBalance + fullBalance - unlockedBalance),
        super(unlockedBalance, fullBalance);

  WowneroBalance.fromString(
      {required this.formattedFullBalance,
        required this.formattedUnlockedBalance,
        this.formattedLockedBalance = '0.0'})
      : fullBalance = wowneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = wowneroParseAmount(amount: formattedUnlockedBalance),
        frozenBalance = wowneroParseAmount(amount: formattedLockedBalance),
        super(wowneroParseAmount(amount: formattedUnlockedBalance),
          wowneroParseAmount(amount: formattedFullBalance));

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