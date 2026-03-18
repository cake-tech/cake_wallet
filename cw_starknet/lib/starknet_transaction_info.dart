// ignore_for_file: overridden_fields

import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class StarknetTransactionInfo extends TransactionInfo {
  StarknetTransactionInfo({
    required this.id,
    required this.blockTime,
    required this.to,
    required this.from,
    required this.direction,
    required this.starknetAmount,
    this.tokenSymbol = "STRK",
    required this.isPending,
    required this.txFee,
  }) : amount = starknetAmount.toInt();

  @override
  final String id;
  @override
  final String? to;
  @override
  final String? from;
  @override
  final int amount;
  @override
  final bool isPending;
  final double starknetAmount;
  final String tokenSymbol;
  final DateTime blockTime;
  final double txFee;
  @override
  final TransactionDirection direction;

  String? _fiatAmount;

  @override
  DateTime get date => blockTime;

  @override
  String amountFormatted() {
    String stringBalance = starknetAmount.toString();
    if (stringBalance.length >= 12) {
      stringBalance = stringBalance.substring(0, 12);
    }
    return '$stringBalance $tokenSymbol';
  }

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => '${txFee.toString()} STRK';

  factory StarknetTransactionInfo.fromJson(Map<String, dynamic> data) {
    return StarknetTransactionInfo(
      id: data['id'] as String,
      starknetAmount: (data['starknetAmount'] as num).toDouble(),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      blockTime: DateTime.fromMillisecondsSinceEpoch(data['blockTime'] as int),
      isPending: data['isPending'] as bool,
      tokenSymbol: data['tokenSymbol'] as String? ?? "STRK",
      to: data['to'] as String?,
      from: data['from'] as String?,
      txFee: (data['txFee'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'starknetAmount': starknetAmount,
        'direction': direction.index,
        'blockTime': blockTime.millisecondsSinceEpoch,
        'isPending': isPending,
        'tokenSymbol': tokenSymbol,
        'to': to,
        'from': from,
        'txFee': txFee,
      };
}
