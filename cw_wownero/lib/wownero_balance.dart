import 'package:cw_core/balance.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_wownero/wownero_amount_format.dart';

class WowneroBalance extends Balance {
  WowneroBalance({@required this.fullBalance, @required this.unlockedBalance})
      : formattedFullBalance = wowneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
        wowneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  WowneroBalance.fromString(
      {@required this.formattedFullBalance,
        @required this.formattedUnlockedBalance})
      : fullBalance = wowneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = wowneroParseAmount(amount: formattedUnlockedBalance),
        super(wowneroParseAmount(amount: formattedUnlockedBalance),
          wowneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}
