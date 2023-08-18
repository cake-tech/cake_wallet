import 'package:cw_core/balance.dart';
import 'package:cw_core/monero_amount_format.dart';

class MoneroBalance extends Balance {
  MoneroBalance({required this.fullBalance, required this.unlockedBalance, this.frozenBalance = 0})
      : formattedFullBalance = moneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance = moneroAmountToString(amount: unlockedBalance),
        formattedFrozenBalance = moneroAmountToString(amount: frozenBalance),
        super(unlockedBalance, fullBalance);

  MoneroBalance.fromString(
      {required this.formattedFullBalance,
      required this.formattedUnlockedBalance,
      this.formattedFrozenBalance = '0.0'})
      : fullBalance = moneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = moneroParseAmount(amount: formattedUnlockedBalance),
        frozenBalance = moneroParseAmount(amount: formattedFrozenBalance),
        super(moneroParseAmount(amount: formattedUnlockedBalance),
            moneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final int frozenBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  final String formattedFrozenBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}
