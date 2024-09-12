import 'dart:convert';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/balance.dart';

class ElectrumBalance extends Balance {
  ElectrumBalance({
    required this.confirmed,
    required this.unconfirmed,
    required this.frozen,
    this.secondConfirmed,
    this.secondUnconfirmed,
  }) : super(
          confirmed,
          unconfirmed,
          secondAvailable: secondConfirmed,
          secondAdditional: secondUnconfirmed,
        );

  static ElectrumBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    return ElectrumBalance(
        confirmed: decoded['confirmed'] as int? ?? 0,
        unconfirmed: decoded['unconfirmed'] as int? ?? 0,
        frozen: decoded['frozen'] as int? ?? 0);
  }

  int confirmed;
  int unconfirmed;
  final int frozen;
  int? secondConfirmed;
  int? secondUnconfirmed;

  @override
  String get formattedAvailableBalance => bitcoinAmountToString(amount: confirmed - frozen);

  @override
  String get formattedAdditionalBalance => bitcoinAmountToString(amount: unconfirmed);

  @override
  String get formattedUnAvailableBalance {
    final frozenFormatted = bitcoinAmountToString(amount: frozen);
    return frozenFormatted == '0.0' ? '' : frozenFormatted;
  }

  @override
  String get formattedSecondAvailableBalance => bitcoinAmountToString(amount: secondConfirmed ?? 0);

  @override
  String get formattedSecondAdditionalBalance => bitcoinAmountToString(amount: secondUnconfirmed ?? 0);

  String toJSON() => json.encode({
        'confirmed': confirmed,
        'unconfirmed': unconfirmed,
        'frozen': frozen,
        'secondConfirmed': secondConfirmed,
        'secondUnconfirmed': secondUnconfirmed
      });
}
