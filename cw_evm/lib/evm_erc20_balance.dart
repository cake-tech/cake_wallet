import 'dart:convert';
import 'dart:math';

import 'package:cw_core/balance.dart';

class EVMChainERC20Balance extends Balance {
  EVMChainERC20Balance(this.balance, {this.exponent = 18})
      : super(balance.toInt(), balance.toInt());

  final BigInt balance;
  final int exponent;

  @override
  String get formattedAdditionalBalance {
    final String formattedBalance = (balance / BigInt.from(10).pow(exponent)).toString();
    return formattedBalance.substring(0, min(12, formattedBalance.length));
  }

  @override
  String get formattedAvailableBalance {
    final String formattedBalance = (balance / BigInt.from(10).pow(exponent)).toString();
    return formattedBalance.substring(0, min(12, formattedBalance.length));
  }

  String toJSON() => json.encode({
        'balanceInWei': balance.toString(),
        'exponent': exponent,
      });

  static EVMChainERC20Balance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return EVMChainERC20Balance(
        BigInt.parse(decoded['balanceInWei']),
        exponent: decoded['exponent'],
      );
    } catch (e) {
      return EVMChainERC20Balance(BigInt.zero);
    }
  }
}
