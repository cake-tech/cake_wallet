import 'package:cake_wallet/entities/balance.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/monero/monero_amount_format.dart';

class MoneroBalance extends Balance {
  MoneroBalance({@required this.fullBalance, @required this.unlockedBalance})
      : formattedFullBalance = moneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            moneroAmountToString(amount: unlockedBalance),
        super(const [
          BalanceDisplayMode.availableBalance,
          BalanceDisplayMode.fullBalance
        ]);

  MoneroBalance.fromString(
      {@required this.formattedFullBalance,
      @required this.formattedUnlockedBalance})
      : fullBalance = moneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = moneroParseAmount(amount: formattedUnlockedBalance),
        super(const [
          BalanceDisplayMode.availableBalance,
          BalanceDisplayMode.fullBalance
        ]);

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String formattedBalance(BalanceDisplayMode mode) {
    switch (mode) {
      case BalanceDisplayMode.fullBalance:
        return formattedFullBalance;
      case BalanceDisplayMode.availableBalance:
        return formattedUnlockedBalance;
      default:
        return null;
    }
  }
}
