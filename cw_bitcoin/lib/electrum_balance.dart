import 'dart:convert';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/balance.dart';

class ElectrumBalance extends Balance {
  ElectrumBalance({
    required this.confirmed,
    required this.unconfirmed,
    required this.frozen,
    this.selected = 0,
    this.secondConfirmed = 0,
    this.secondUnconfirmed = 0,
  }) : super(
          confirmed,
          unconfirmed,
          secondAvailable: secondConfirmed,
          secondAdditional: secondUnconfirmed,
          selected: selected,
        );

  static ElectrumBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    return ElectrumBalance(
      confirmed: decoded['confirmed'] as int? ?? 0,
      unconfirmed: decoded['unconfirmed'] as int? ?? 0,
      frozen: decoded['frozen'] as int? ?? 0,
      secondConfirmed: decoded['secondConfirmed'] as int? ?? 0,
      secondUnconfirmed: decoded['secondUnconfirmed'] as int? ?? 0,
      selected: decoded['selected'] as int? ?? 0,
    );
  }

  int confirmed;
  int unconfirmed;
  final int frozen;
  int selected = 0;
  int secondConfirmed = 0;
  int secondUnconfirmed = 0;

  @override
  String get formattedAvailableBalance => bitcoinAmountToString(amount: ((confirmed + unconfirmed) - frozen) );

  @override
  String get formattedAdditionalBalance => bitcoinAmountToString(amount: unconfirmed);

  @override
  String get formattedUnAvailableBalance {
    final frozenFormatted = bitcoinAmountToString(amount: frozen);
    return frozenFormatted == '0.0' ? '' : frozenFormatted;
  }

  @override
  String get formattedSecondAvailableBalance => bitcoinAmountToString(amount: secondConfirmed);

  @override
  String get formattedSecondAdditionalBalance => bitcoinAmountToString(amount: secondUnconfirmed);

  @override
  String get formattedFullAvailableBalance =>
      bitcoinAmountToString(amount: (confirmed + unconfirmed) + secondConfirmed - frozen);

  @override
  String get formattedSelectedBalance => bitcoinAmountToString(amount: selected);

  String toJSON() => json.encode({
        'confirmed': confirmed,
        'unconfirmed': unconfirmed,
        'frozen': frozen,
        'secondConfirmed': secondConfirmed,
        'secondUnconfirmed': secondUnconfirmed
      });
}
