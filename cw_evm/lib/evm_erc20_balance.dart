import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

import 'package:cw_core/balance.dart';

class EVMChainERC20Balance extends Balance {
  EVMChainERC20Balance(this.balance, {this.exponent = 18})
      : super(balance.toInt(), balance.toInt());

  final BigInt balance;
  final int exponent;

  @override
  String get formattedAdditionalBalance => _balance();

  @override
  String get formattedAvailableBalance => _balance();

  String _balance() {
    NumberFormat formatter = NumberFormat('0.00##########', 'en_US');
    double numBalance = (balance / BigInt.from(10).pow(exponent)).toDouble();
    String formattedBalance = formatter.format(numBalance);
    return formattedBalance;
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
