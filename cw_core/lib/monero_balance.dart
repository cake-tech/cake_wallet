import 'package:cw_core/balance.dart';
import 'package:cw_core/monero_amount_format.dart';

class MoneroBalance extends Balance {
  MoneroBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedFullBalance = moneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            moneroAmountToString(amount: unlockedBalance),
        formattedFrozen = '',
        formattedTotalAvailable = '',
        super(unlockedBalance, fullBalance);

  MoneroBalance.fromString(
      {required this.formattedFullBalance,
      required this.formattedUnlockedBalance,
      required this.formattedFrozen,
      required this.formattedTotalAvailable})
      : fullBalance = moneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = moneroParseAmount(amount: formattedUnlockedBalance),
        super(moneroParseAmount(amount: formattedUnlockedBalance),
            moneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;
  final String formattedFrozen;
  final String formattedTotalAvailable;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;

  @override
  String get formattedFrozenBalance => formattedFrozen;

  @override
  String get formattedTotalAvailableBalance => formattedTotalAvailable;
}
