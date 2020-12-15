import 'dart:convert';

import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/entities/balance.dart';

class BitcoinBalance extends Balance {
  const BitcoinBalance({@required this.confirmed, @required this.unconfirmed})
      : super(const [BalanceDisplayMode.availableBalance]);

  factory BitcoinBalance.fromJSON(String jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    return BitcoinBalance(
        confirmed: decoded['confirmed'] as int ?? 0,
        unconfirmed: decoded['unconfirmed'] as int ?? 0);
  }

  final int confirmed;
  final int unconfirmed;

  int get total => confirmed + unconfirmed;

  String get confirmedFormatted => bitcoinAmountToString(amount: confirmed);

  String get unconfirmedFormatted => bitcoinAmountToString(amount: unconfirmed);

  String get totalFormatted => bitcoinAmountToString(amount: total);

  @override
  String formattedBalance(BalanceDisplayMode mode) {
    switch (mode) {
      case BalanceDisplayMode.fullBalance:
        return totalFormatted;
      case BalanceDisplayMode.availableBalance:
        return totalFormatted;
      default:
        return null;
    }
  }

  String toJSON() =>
      json.encode({'confirmed': confirmed, 'unconfirmed': unconfirmed});
}
