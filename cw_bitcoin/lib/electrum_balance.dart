import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/balance.dart';

class ElectrumBalance extends Balance {
  const ElectrumBalance({@required this.confirmed, @required this.unconfirmed})
      : super(confirmed, unconfirmed);

  factory ElectrumBalance.fromJSON(String jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    return ElectrumBalance(
        confirmed: decoded['confirmed'] as int ?? 0,
        unconfirmed: decoded['unconfirmed'] as int ?? 0);
  }

  final int confirmed;
  final int unconfirmed;

  @override
  String get formattedAvailableBalance =>
      bitcoinAmountToString(amount: confirmed);

  @override
  String get formattedAdditionalBalance =>
      bitcoinAmountToString(amount: unconfirmed);

  String toJSON() =>
      json.encode({'confirmed': confirmed, 'unconfirmed': unconfirmed});
}
