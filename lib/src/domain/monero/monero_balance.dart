import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';

class MoneroBalance extends Balance {
  final String fullBalance;
  final String unlockedBalance;

  MoneroBalance({@required this.fullBalance, @required this.unlockedBalance});
}
