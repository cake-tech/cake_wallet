import 'package:cw_core/balance.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:tari/tari.dart' as tari;

class TariBalance extends Balance {
  TariBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedUnconfirmedBalance =
            moneroAmountToString(amount: fullBalance - unlockedBalance),
        formattedUnlockedBalance =
            moneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  factory TariBalance.fromTariBalanceInfo(tari.TariBalanceInfo result) {
    return TariBalance(
        fullBalance: result.available +
            result.pendingIncoming +
            result.pendingOutgoing +
            result.timeLocked,
        unlockedBalance: result.available);
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
