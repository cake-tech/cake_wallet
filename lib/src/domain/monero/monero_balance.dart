import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';

class MoneroBalance extends Balance {
  MoneroBalance({@required this.fullBalance, @required this.unlockedBalance});

  final String fullBalance;
  final String unlockedBalance;
}
