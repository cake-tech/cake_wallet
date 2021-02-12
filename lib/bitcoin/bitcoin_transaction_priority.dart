import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/generated/i18n.dart';

class BitcoinTransactionPriority extends TransactionPriority {
  const BitcoinTransactionPriority({String title, int raw})
      : super(title: title, raw: raw);

  static const List<BitcoinTransactionPriority> all = [fast, medium, slow];
  static const BitcoinTransactionPriority slow =
      BitcoinTransactionPriority(title: 'Slow', raw: 0);
  static const BitcoinTransactionPriority medium =
      BitcoinTransactionPriority(title: 'Medium', raw: 1);
  static const BitcoinTransactionPriority fast =
      BitcoinTransactionPriority(title: 'Fast', raw: 2);

  static BitcoinTransactionPriority deserialize({int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        return null;
    }
  }

  @override
  String toString() {
    var label = '';

    switch (this) {
      case BitcoinTransactionPriority.slow:
        label = S.current.transaction_priority_slow;
        break;
      case BitcoinTransactionPriority.medium:
        label = S.current.transaction_priority_medium;
        break;
      case BitcoinTransactionPriority.fast:
        label = S.current.transaction_priority_fast;
        break;
      default:
        break;
    }

    return label;
  }
}
