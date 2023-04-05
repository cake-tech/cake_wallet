import 'dart:convert';

import 'package:cw_core/balance.dart';
import 'package:web3dart/web3dart.dart';

class EthereumBalance extends Balance {
  EthereumBalance(this.balance)
      : super(balance.getValueInUnit(EtherUnit.wei).toInt(),
            balance.getValueInUnit(EtherUnit.wei).toInt());

  final EtherAmount balance;

  @override
  String get formattedAdditionalBalance => balance.getValueInUnit(EtherUnit.ether).toString();

  @override
  String get formattedAvailableBalance => balance.getValueInUnit(EtherUnit.ether).toString();

  String toJSON() => json.encode({'balanceInWei': balance.getInWei.toString()});

  static EthereumBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return EthereumBalance(EtherAmount.inWei(BigInt.parse(decoded['balanceInWei'])));
    } catch (e) {
      return EthereumBalance(EtherAmount.zero());
    }
  }
}
