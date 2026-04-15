import 'dart:convert';

import 'package:cw_core/balance.dart';
import 'package:cw_core/format_fixed.dart';

String truncateDecimalString(String value, {int maxLength = 12}) =>
    value.length >= maxLength ? value.substring(0, maxLength) : value;

class StarknetBalance extends Balance {
  StarknetBalance(
    this.rawBalance, {
    required this.decimals,
  }) : super(rawBalance, rawBalance);

  final BigInt rawBalance;
  final int decimals;

  double get balance => double.tryParse(_balanceFormatted()) ?? 0.0;

  String get formattedAdditionalBalance => _balanceFormatted();

  String get formattedAvailableBalance => _balanceFormatted();

  String _balanceFormatted() =>
      truncateDecimalString(formatFixed(rawBalance, decimals, fractionalDigits: decimals));

  static StarknetBalance zero({int decimals = 18}) =>
      StarknetBalance(BigInt.zero, decimals: decimals);

  static StarknetBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    try {
      return StarknetBalance(
        BigInt.parse(decoded['raw_balance']?.toString() ?? '0'),
        decimals: int.tryParse(decoded['decimals']?.toString() ?? '') ?? 18,
      );
    } catch (_) {
      return StarknetBalance.zero();
    }
  }

  String toJSON() => json.encode({
        'raw_balance': rawBalance.toString(),
        'decimals': decimals,
      });
}
