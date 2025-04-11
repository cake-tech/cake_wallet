import 'package:cw_core/balance.dart';
import 'package:cw_core/monero_amount_format.dart';

class TariBalance extends Balance {
  TariBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedUnconfirmedBalance =
            moneroAmountToString(amount: fullBalance - unlockedBalance),
        formattedUnlockedBalance =
            moneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  factory TariBalance.fromFfi((int, int, int, int) result) {
    final availableBalance = result.$1;
    final pendingIncoming = result.$2;
    final pendingOutgoing = result.$3;
    final timeLockedBalance = result.$4;

    return TariBalance(
        fullBalance: availableBalance +
            pendingIncoming +
            pendingOutgoing +
            timeLockedBalance,
        unlockedBalance: availableBalance);
  }

  final int fullBalance;
  final int unlockedBalance;
  final String formattedUnconfirmedBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedUnconfirmedBalance;
}
