import 'package:cw_core/balance.dart';
import 'package:cw_core/monero_amount_format.dart';

class MoneroBalance extends Balance {
  MoneroBalance({required this.fullBalance, required this.unlockedBalance, this.frozenBalance = 0})
      : formattedUnconfirmedBalance = moneroAmountToString(amount: fullBalance - unlockedBalance),
        formattedUnlockedBalance = moneroAmountToString(amount: unlockedBalance),
        formattedFrozenBalance = moneroAmountToString(amount: frozenBalance),
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
