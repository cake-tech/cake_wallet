import 'dart:convert';

import 'package:cw_core/balance.dart';

class ElectrumBalance extends Balance {
  ElectrumBalance({
    required this.confirmed,
    required this.unconfirmed,
    required int frozen,
    this.secondConfirmed = 0,
    this.secondUnconfirmed = 0,
  }) : this._frozen = frozen, super.fromInt(confirmed, unconfirmed,
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
  final int _frozen;

  @override
  BigInt get frozen => BigInt.from(_frozen);

  int secondConfirmed = 0;
  int secondUnconfirmed = 0;

  @override
  BigInt get fullAvailableBalance => BigInt.from((confirmed + unconfirmed) + secondConfirmed - _frozen);

  String toJSON() => json.encode({
        'confirmed': confirmed,
        'unconfirmed': unconfirmed,
        'frozen': _frozen,
        'secondConfirmed': secondConfirmed,
        'secondUnconfirmed': secondUnconfirmed,
      });
}
