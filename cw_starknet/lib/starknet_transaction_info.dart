// ignore_for_file: overridden_fields

import 'package:cw_core/format_fixed.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_starknet/starknet_balance.dart' show truncateDecimalString;

class StarknetTransactionInfo extends TransactionInfo {
  StarknetTransactionInfo({
    required this.id,
    required this.transactionHash,
    required this.blockTime,
    required this.to,
    required this.from,
    required this.direction,
    required this.amountWei,
    required this.tokenAddress,
    required this.tokenDecimals,
    required this.tokenSymbol,
    required this.isPending,
    required this.txFeeWei,
  }) : amount = _safeAmountInt(amountWei) {
    txHash = transactionHash;
  }

  @override
  final String id;

  final String transactionHash;

  @override
  final String? to;

  @override
  final String? from;

  @override
  final int amount;

  @override
  final bool isPending;

  final String amountWei;
  final String tokenAddress;
  final int tokenDecimals;
  final String tokenSymbol;
  final DateTime blockTime;
  final String txFeeWei;

  @override
  final TransactionDirection direction;

  String? _fiatAmount;

  @override
  DateTime get date => blockTime;

  double rawAmountAsDouble() => double.tryParse(
          formatFixed(BigInt.parse(amountWei), tokenDecimals, fractionalDigits: tokenDecimals)) ??
      0.0;

  @override
  String amountFormatted() =>
      '${truncateDecimalString(formatFixed(BigInt.parse(amountWei), tokenDecimals, fractionalDigits: tokenDecimals))} $tokenSymbol';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => txFeeWei.isEmpty
      ? ''
      : '${truncateDecimalString(formatFixed(BigInt.parse(txFeeWei), 18, fractionalDigits: 18))} STRK';

  factory StarknetTransactionInfo.fromJson(Map<String, dynamic> data) {
    return StarknetTransactionInfo(
      id: data['id'] as String,
      transactionHash: data['transactionHash'] as String? ?? data['id'] as String,
      amountWei: data['amountWei']?.toString() ?? '0',
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      blockTime: DateTime.fromMillisecondsSinceEpoch(data['blockTime'] as int),
      isPending: data['isPending'] as bool,
      tokenAddress: data['tokenAddress']?.toString() ?? '',
      tokenDecimals: (data['tokenDecimals'] as num?)?.toInt() ?? 18,
      tokenSymbol: data['tokenSymbol'] as String? ?? 'STRK',
      to: data['to'] as String?,
      from: data['from'] as String?,
      txFeeWei: data['txFeeWei']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transactionHash': transactionHash,
        'amountWei': amountWei,
        'direction': direction.index,
        'blockTime': blockTime.millisecondsSinceEpoch,
        'isPending': isPending,
        'tokenAddress': tokenAddress,
        'tokenDecimals': tokenDecimals,
        'tokenSymbol': tokenSymbol,
        'to': to,
        'from': from,
        'txFeeWei': txFeeWei,
      };

  static int _safeAmountInt(String value) {
    final parsed = BigInt.tryParse(value) ?? BigInt.zero;
    if (parsed > BigInt.from(0x7fffffffffffffff)) {
      return 0x7fffffffffffffff;
    }

    return parsed.toInt();
  }
}
