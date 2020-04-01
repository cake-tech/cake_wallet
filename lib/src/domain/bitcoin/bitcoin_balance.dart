import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';

class BitcoinBalance extends Balance {
  BitcoinBalance({@required this.fullBalance, @required this.unlockedBalance});

  final String fullBalance;
  final String unlockedBalance;
}