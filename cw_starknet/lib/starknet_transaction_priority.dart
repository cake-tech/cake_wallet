import 'package:cw_core/transaction_priority.dart';
import 'package:flutter/foundation.dart';

class StarknetTransactionPriority extends TransactionPriority {
  const StarknetTransactionPriority({
    required String title,
    required int raw,
    required this.gasAmountMultiplier,
    required this.gasPriceMultiplier,
    required this.tipMultiplier,
  }) : super(title: title, raw: raw);

  final double gasAmountMultiplier;
  final double gasPriceMultiplier;
  final double tipMultiplier;

  static const List<StarknetTransactionPriority> all = [slow, medium, fast];

  static const StarknetTransactionPriority slow = StarknetTransactionPriority(
    title: 'Slow',
    raw: 0,
    gasAmountMultiplier: 1.15,
    gasPriceMultiplier: 1.10,
    tipMultiplier: 0.5,
  );

  static const StarknetTransactionPriority medium = StarknetTransactionPriority(
    title: 'Medium',
    raw: 1,
    gasAmountMultiplier: 1.35,
    gasPriceMultiplier: 1.30,
    tipMultiplier: 1.0,
  );

  static const StarknetTransactionPriority fast = StarknetTransactionPriority(
    title: 'Fast',
    raw: 2,
    gasAmountMultiplier: 1.60,
    gasPriceMultiplier: 1.50,
    tipMultiplier: 2.0,
  );

  static StarknetTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        if (kDebugMode) {
          throw Exception(
            'Unexpected token: $raw for StarknetTransactionPriority deserialize',
          );
        }
        return medium;
    }
  }

  @override
  String toString() {
    switch (this) {
      case StarknetTransactionPriority.slow:
        return 'Slow';
      case StarknetTransactionPriority.medium:
        return 'Medium';
      case StarknetTransactionPriority.fast:
        return 'Fast';
      default:
        return title;
    }
  }
}
