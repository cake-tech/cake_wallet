import 'package:cw_core/balance.dart';
import 'package:cw_core/wownero_amount_format.dart';

class WowneroBalance extends Balance {
  WowneroBalance({required this.fullBalance, required this.unlockedBalance, this.frozenBalance = 0})
      : formattedUnconfirmedBalance = wowneroAmountToString(amount: fullBalance - unlockedBalance),
        formattedUnlockedBalance = wowneroAmountToString(amount: unlockedBalance - frozenBalance),
        formattedFrozenBalance =
        wowneroAmountToString(amount: frozenBalance),
        super(unlockedBalance, fullBalance);

  WowneroBalance.fromString(
      {required this.formattedUnconfirmedBalance,
      required this.formattedUnlockedBalance,
      this.formattedFrozenBalance = '0.0'})
      : fullBalance = wowneroParseAmount(amount: formattedUnconfirmedBalance),
        unlockedBalance = wowneroParseAmount(amount: formattedUnlockedBalance),
        frozenBalance = wowneroParseAmount(amount: formattedFrozenBalance),
        super(wowneroParseAmount(amount: formattedUnlockedBalance),
          wowneroParseAmount(amount: formattedUnconfirmedBalance));

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