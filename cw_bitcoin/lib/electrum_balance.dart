import 'dart:convert';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/currency.dart';

class ElectrumBalance extends Balance {
  ElectrumBalance({
    required this.confirmed,
    required this.unconfirmed,
    required this.frozen,
    this.secondConfirmed,
    this.secondUnconfirmed,
  }) : super(confirmed, unconfirmed,
            secondAvailable: secondConfirmed, secondUnavailable: secondUnconfirmed);

  Money confirmed;
  Money unconfirmed;
  Money? secondConfirmed;
  Money? secondUnconfirmed;

  @override
  Money get available => (confirmed + unconfirmed) - frozen;

  @override
  Money get unavailable => unconfirmed;

  @override
  Money frozen;

  static ElectrumBalance? fromJSON(String? jsonSource, Currency currency) {
    if (jsonSource == null) return null;

    final decoded = json.decode(jsonSource) as Map;

    return ElectrumBalance(
      confirmed: Money.fromInt(decoded['confirmed'] as int? ?? 0, currency),
      unconfirmed: Money.fromInt(decoded['unconfirmed'] as int? ?? 0, currency),
      frozen: Money.fromInt(decoded['frozen'] as int? ?? 0, currency),
      secondConfirmed: Money.fromInt(decoded['secondConfirmed'] as int? ?? 0, currency),
      secondUnconfirmed: Money.fromInt(decoded['secondUnconfirmed'] as int? ?? 0, currency),
    );
  }

  String toJSON() => json.encode({
        'confirmed': confirmed.amount.toInt(),
        'unconfirmed': unavailable.amount.toInt(),
        'frozen': frozen.amount.toInt(),
        'secondConfirmed': secondAvailable?.amount.toInt() ?? 0,
        'secondUnconfirmed': secondUnavailable?.amount.toInt() ?? 0,
      });
}
