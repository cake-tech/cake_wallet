import 'dart:convert';

import 'package:cw_core/balance.dart';
import 'package:web3dart/web3dart.dart';

class EthereumBalance extends Balance {
  EthereumBalance(super.available, super.additional);

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
}
