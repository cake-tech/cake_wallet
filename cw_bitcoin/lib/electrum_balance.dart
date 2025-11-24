import 'dart:convert';

import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/format_fixed.dart';

class ElectrumBalance extends Balance {
  ElectrumBalance({
    required this.confirmed,
    required this.unconfirmed,
    required this.frozen,
    this.secondConfirmed = 0,
    this.secondUnconfirmed = 0,
    this.showInSats = false,
  }) : super(
          confirmed,
          unconfirmed,
          secondAvailable: secondConfirmed,
          secondAdditional: secondUnconfirmed,
        );

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
  final int frozen;
  int secondConfirmed = 0;
  int secondUnconfirmed = 0;
  bool showInSats;

  @override
  String get formattedAvailableBalance => showInSats
      ? ((confirmed + unconfirmed) - frozen).toString()
      : formatFixed(BigInt.from((confirmed + unconfirmed) - frozen), CryptoCurrency.btc.decimals);

  @override
  String get formattedAdditionalBalance => showInSats
      ? unconfirmed.toString()
      : formatFixed(BigInt.from(unconfirmed), CryptoCurrency.btc.decimals);

  @override
  String get formattedUnAvailableBalance {
    if (frozen == 0) return '';
    return showInSats
        ? frozen.toString()
        : formatFixed(BigInt.from(frozen), CryptoCurrency.btc.decimals);
  }

  @override
  String get formattedSecondAvailableBalance => showInSats
      ? secondConfirmed.toString()
      : formatFixed(BigInt.from(secondConfirmed), CryptoCurrency.btc.decimals);

  @override
  String get formattedSecondAdditionalBalance => showInSats
      ? secondUnconfirmed.toString()
      : formatFixed(BigInt.from(secondUnconfirmed), CryptoCurrency.btc.decimals);

  @override
  String get formattedFullAvailableBalance => showInSats
      ? ((confirmed + unconfirmed) + secondConfirmed - frozen).toString()
      : formatFixed(BigInt.from((confirmed + unconfirmed) + secondConfirmed - frozen),
          CryptoCurrency.btc.decimals);

  String toJSON() => json.encode({
        'confirmed': confirmed,
        'unconfirmed': unconfirmed,
        'frozen': frozen,
        'secondConfirmed': secondConfirmed,
        'secondUnconfirmed': secondUnconfirmed,
      });
}
