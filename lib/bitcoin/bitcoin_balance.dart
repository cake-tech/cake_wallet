import 'package:flutter/foundation.dart';
import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';

class BitcoinBalance extends Balance {
  BitcoinBalance({@required this.confirmed, @required this.unconfirmed});

  final int confirmed;
  final int unconfirmed;
  int get total => confirmed + unconfirmed;
  String get confirmedFormatted => bitcoinAmountToString(amount: confirmed);
  String get unconfirmedFormatted => bitcoinAmountToString(amount: unconfirmed);
  String get totalFormatted => bitcoinAmountToString(amount: total);
}
