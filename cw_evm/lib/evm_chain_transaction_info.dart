// ignore_for_file: annotate_overrides, overridden_fields

import 'dart:math';

import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class EVMChainTransactionInfo extends TransactionInfo {
  EVMChainTransactionInfo({
    required this.id,
    required this.height,
    required this.ethAmount,
    required this.ethFee,
    required this.tokenSymbol,
    this.exponent = 18,
    required this.direction,
    required this.isPending,
    required this.date,
    required this.confirmations,
    required this.to,
  })  : amount = ethAmount.toInt(),
        fee = ethFee.toInt();

  final String id;
  final int height;
  final int amount;
  final BigInt ethAmount;
  final int exponent;
  final TransactionDirection direction;
  final DateTime date;
  final bool isPending;
  final int fee;
  final BigInt ethFee;
  final int confirmations;
  final String tokenSymbol;
  String? _fiatAmount;
  final String? to;

  @override
  String amountFormatted() {
    final amount = formatAmount((ethAmount / BigInt.from(10).pow(exponent)).toString());
    return '${amount.substring(0, min(10, amount.length))} $tokenSymbol';
  }

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() {
    final amount = (ethFee / BigInt.from(10).pow(18)).toString();
    return '${amount.substring(0, min(10, amount.length))} $tokenSymbol';
  }

  factory EVMChainTransactionInfo.fromJson(Map<String, dynamic> data) {
    return EVMChainTransactionInfo(
      id: data['id'] as String,
      height: data['height'] as int,
      ethAmount: BigInt.parse(data['amount']),
      exponent: data['exponent'] as int,
      ethFee: BigInt.parse(data['fee']),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      isPending: data['isPending'] as bool,
      confirmations: data['confirmations'] as int,
      tokenSymbol: data['tokenSymbol'] as String,
      to: data['to'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'height': height,
        'amount': ethAmount.toString(),
        'exponent': exponent,
        'fee': ethFee.toString(),
        'direction': direction.index,
        'date': date.millisecondsSinceEpoch,
        'isPending': isPending,
        'confirmations': confirmations,
        'tokenSymbol': tokenSymbol,
        'to': to,
      };
}
