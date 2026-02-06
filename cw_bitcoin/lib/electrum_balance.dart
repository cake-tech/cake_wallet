import 'dart:convert';

import 'package:cw_core/balance.dart';

class ElectrumBalance extends Balance {
  ElectrumBalance({
    required this.confirmed,
    required this.unconfirmed,
    required this.frozen,
    this.secondConfirmed = 0,
    this.secondUnconfirmed = 0,
  }) : super(confirmed, unconfirmed,
            secondAvailable: secondConfirmed, secondAdditional: secondUnconfirmed, frozen: frozen);

  static ElectrumBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) return null;

    final decoded = json.decode(jsonSource) as Map;

    return ElectrumBalance(
      confirmed: decoded['confirmed'] as int? ?? 0,
      unconfirmed: decoded['unconfirmed'] as int? ?? 0,
      frozen: decoded['frozen'] as int? ?? 0,
      secondConfirmed: decoded['secondConfirmed'] as int? ?? 0,
      secondUnconfirmed: decoded['secondUnconfirmed'] as int? ?? 0,
    );
  }

  int confirmed;
  int unconfirmed;
  @override
  final int frozen;

  int secondConfirmed = 0;
  int secondUnconfirmed = 0;

  @override
  int get fullAvailableBalance => (confirmed + unconfirmed) + secondConfirmed - frozen;

  String toJSON() => json.encode({
        'confirmed': confirmed,
        'unconfirmed': unconfirmed,
        'frozen': frozen,
        'secondConfirmed': secondConfirmed,
        'secondUnconfirmed': secondUnconfirmed,
      });
}
