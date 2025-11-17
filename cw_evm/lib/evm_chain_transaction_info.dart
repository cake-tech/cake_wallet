// ignore_for_file: overridden_fields, annotate_overrides

import 'dart:math';

import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/utils/evm_chain_utils.dart';

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
    required this.from,
    this.evmSignatureName,
    this.contractAddress,
    required WalletType walletType,
    required this.chainId,
  })  : amount = ethAmount.toInt(),
        fee = ethFee.toInt(),
        _walletType = walletType;

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
  final String? from;
  final String? evmSignatureName;
  final String? contractAddress;
  final WalletType _walletType;
  final int chainId;

  /// Get fee currency symbol based on wallet type
  String get feeCurrency => EVMChainUtils.getFeeCurrency(_walletType);

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
    return '${amount.substring(0, min(18, amount.length))} $feeCurrency';
  }

  /// Factory constructor to create from JSON
  factory EVMChainTransactionInfo.fromJson(
    Map<String, dynamic> data,
    WalletType walletType,
  ) {
    return EVMChainTransactionInfo(
      id: data['id'] as String,
      height: data['height'] as int,
      ethAmount: BigInt.parse(data['amount'] as String),
      exponent: data['exponent'] as int? ?? 18,
      ethFee: BigInt.parse(data['fee'] as String),
      direction: TransactionDirection.values[data['direction'] as int],
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      isPending: data['isPending'] as bool? ?? false,
      confirmations: data['confirmations'] as int,
      tokenSymbol: data['tokenSymbol'] as String,
      to: data['to'] as String?,
      from: data['from'] as String?,
      evmSignatureName: data['evmSignatureName'] as String?,
      contractAddress: data['contractAddress'] as String?,
      walletType: walletType,
      chainId: data['chainId'] as int? ?? 1,
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
        'from': from,
        'evmSignatureName': evmSignatureName,
        'contractAddress': contractAddress,
        'chainId': chainId,
      };
}
