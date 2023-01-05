import 'dart:convert';

import 'package:cw_core/balance.dart';
import 'package:web3dart/web3dart.dart';

class EthereumBalance extends Balance {
  EthereumBalance({required int available, required int additional}) : super(available, additional);

  @override
  String get formattedAdditionalBalance {
    return EtherAmount.fromUnitAndValue(EtherUnit.ether, additional.toString())
        .getInEther
        .toString();
  }

  @override
  String get formattedAvailableBalance =>
      EtherAmount.fromUnitAndValue(EtherUnit.ether, available.toString()).getInEther.toString();

  String toJSON() => json.encode({'available': available, 'additional': additional});

  static EthereumBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    return EthereumBalance(
      available: decoded['available'] as int? ?? 0,
      additional: decoded['additional'] as int? ?? 0,
    );
  }
}
