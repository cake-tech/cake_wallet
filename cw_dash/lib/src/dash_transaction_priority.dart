import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:flutter/foundation.dart';

class DashTransactionPriority extends BitcoinTransactionPriority {
  const DashTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<DashTransactionPriority> all = [fast, medium, slow];
  static const DashTransactionPriority slow =
      DashTransactionPriority(title: 'Slow', raw: 0);
  static const DashTransactionPriority medium =
      DashTransactionPriority(title: 'Medium', raw: 1);
  static const DashTransactionPriority fast =
      DashTransactionPriority(title: 'Fast', raw: 2);

  static DashTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        if (kDebugMode) {
          throw Exception('Unexpected token: $raw for DashTransactionPriority deserialize');
        }
        return medium;
    }
  }

  @override
  String get units => 'duffs';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case DashTransactionPriority.slow:
        label = 'Slow'; // S.current.transaction_priority_slow;
        break;
      case DashTransactionPriority.medium:
        label = 'Medium'; // S.current.transaction_priority_medium;
        break;
      case DashTransactionPriority.fast:
        label = 'Fast'; // S.current.transaction_priority_fast;
        break;
      default:
        break;
    }

    return label;
  }
}
