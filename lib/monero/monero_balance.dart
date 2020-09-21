import 'package:flutter/foundation.dart';
import 'package:cake_wallet/monero/monero_amount_format.dart';

class MoneroBalance {
  MoneroBalance({@required this.fullBalance, @required this.unlockedBalance})
      : formattedFullBalance = moneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
        moneroAmountToString(amount: unlockedBalance);

  MoneroBalance.fromString(
      {@required this.formattedFullBalance,
        @required this.formattedUnlockedBalance})
      : fullBalance = moneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = moneroParseAmount(amount: formattedUnlockedBalance);

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;
}