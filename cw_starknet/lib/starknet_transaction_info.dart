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
    this.evmSignatureName,
    Map<String, dynamic>? additionalInfo,
    this.height,
  }) : amount = _safeAmountInt(amountWei) {
    txHash = transactionHash;
    this.additionalInfo = additionalInfo ?? <String, dynamic>{};
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
  final String? evmSignatureName;

  @override
  final int? height;

  @override
  final TransactionDirection direction;

  String? _fiatAmount;

  @override
  DateTime get date => blockTime;

  double rawAmountAsDouble() =>
      double.tryParse(
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
  String feeFormatted() => txFeeWei.isEmpty ? '' : _formatStrkFee(txFeeWei);

  String? actionLabel() {
    final explicitLabel = additionalInfo['starknetActionLabel']?.toString().trim();
    if (explicitLabel != null && explicitLabel.isNotEmpty) {
      return explicitLabel;
    }

    final actionName = evmSignatureName?.trim();
    if (actionName == null || actionName.isEmpty) {
      return null;
    }

    final normalized = actionName.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String? executionFeeFormatted() {
    final value = additionalInfo['starknetExecutionFeeWei']?.toString();
    if (value == null || value.isEmpty) {
      return null;
    }

    return _formatStrkFee(value);
  }

  String? deployAccountFeeFormatted() {
    final value = additionalInfo['starknetDeployAccountFeeWei']?.toString();
    if (value == null || value.isEmpty) {
      return null;
    }

    return _formatStrkFee(value);
  }

  String? feePriorityLabel() {
    final value = additionalInfo['starknetFeePriorityLabel']?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? transactionTypeLabel() => _humanizeAdditionalInfoValue('starknetTransactionType');

  String? executionStatusLabel() => _humanizeAdditionalInfoValue('starknetExecutionStatus');

  String? finalityStatusLabel() => _humanizeAdditionalInfoValue('starknetFinalityStatus');

  String? revertReason() => _stringAdditionalInfo('starknetRevertReason');

  String? callCountLabel() {
    final value = additionalInfo['starknetCallCount'];
    if (value == null) {
      return null;
    }

    return value.toString();
  }

  String? primaryContractAddress() => _stringAdditionalInfo('starknetPrimaryContract');

  String? primaryEntrypoint() => _stringAdditionalInfo('starknetPrimaryEntrypoint');

  String? transactionTipLabel() {
    final value = additionalInfo['starknetTip'];
    if (value == null) {
      return null;
    }

    return value.toString();
  }

  String? l1GasMaxAmount() => _stringAdditionalInfo('starknetL1GasMaxAmount');

  String? l1GasMaxPriceWei() => _stringAdditionalInfo('starknetL1GasMaxPriceWei');

  String? l2GasMaxAmount() => _stringAdditionalInfo('starknetL2GasMaxAmount');

  String? l2GasMaxPriceWei() => _stringAdditionalInfo('starknetL2GasMaxPriceWei');

  String? l1DataGasMaxAmount() => _stringAdditionalInfo('starknetL1DataGasMaxAmount');

  String? l1DataGasMaxPriceWei() => _stringAdditionalInfo('starknetL1DataGasMaxPriceWei');

  bool get accountDeploymentRequired => additionalInfo['starknetAccountDeploymentRequired'] == true;

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
      evmSignatureName: data['evmSignatureName'] as String?,
      additionalInfo: data['additionalInfo'] == null
          ? null
          : Map<String, dynamic>.from(data['additionalInfo'] as Map),
      height: (data['height'] as num?)?.toInt(),
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
        'evmSignatureName': evmSignatureName,
        'additionalInfo': additionalInfo,
        'height': height,
      };

  static int _safeAmountInt(String value) {
    final parsed = BigInt.tryParse(value) ?? BigInt.zero;
    if (parsed > BigInt.from(0x7fffffffffffffff)) {
      return 0x7fffffffffffffff;
    }

    return parsed.toInt();
  }

  static String _formatStrkFee(String value) => '${truncateDecimalString(
        formatFixed(BigInt.parse(value), 18, fractionalDigits: 18),
      )} STRK';

  String? _stringAdditionalInfo(String key) {
    final value = additionalInfo[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? _humanizeAdditionalInfoValue(String key) {
    final value = _stringAdditionalInfo(key);
    if (value == null) {
      return null;
    }

    final words = value.split('_').where((word) => word.isNotEmpty).map((word) {
      final lower = word.toLowerCase();
      if (lower == 'l1' || lower == 'l2') {
        return word.toUpperCase();
      }

      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');

    return words.isEmpty ? null : words;
  }
}
