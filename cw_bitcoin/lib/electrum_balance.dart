import 'dart:convert';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/currency.dart';

class ElectrumBalance extends Balance {
  ElectrumBalance({
    required this.confirmed,
    required this.unconfirmed,
    required Money frozen,
    Money? secondConfirmed,
    Money? secondUnconfirmed,
  }) : super(
          confirmed,
          unconfirmed,
          secondAvailable: secondConfirmed ?? Money.zero(confirmed.currency),
          secondAdditional: secondUnconfirmed ?? Money.zero(confirmed.currency),
          frozen: frozen,
        );

  Money confirmed;
  Money unconfirmed;

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

  @override
  Money get fullAvailableBalance => ((confirmed + unconfirmed) + secondAvailable! - frozen!);

  String toJSON() => json.encode({
        'confirmed': available.amount.toInt(),
        'unconfirmed': additional.amount.toInt(),
        'frozen': frozen!.amount.toInt(),
        'secondConfirmed': secondAvailable?.amount.toInt() ?? 0,
        'secondUnconfirmed': secondAdditional?.amount.toInt() ?? 0,
      });
}
