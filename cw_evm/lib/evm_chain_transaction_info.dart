// ignore_for_file: overridden_fields, annotate_overrides
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/format_fixed.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

abstract class EVMChainTransactionInfo extends TransactionInfo {
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
  final String? from;
  final String? evmSignatureName;
  final String? contractAddress;

  //! Getter to be overridden in child classes
  String get feeCurrency;

  @override
  String amountFormatted() =>
      '${formatFixed(ethAmount, exponent, fractionalDigits: 10)} $tokenSymbol';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => '${formatFixed(ethFee, 18)} $feeCurrency';

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
      };
}
