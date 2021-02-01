import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/generated/i18n.dart';

class BitcoinTransactionPriority extends TransactionPriority {
  const BitcoinTransactionPriority(this.rate, {String title, int raw})
      : super(title: title, raw: raw);

  static const List<BitcoinTransactionPriority> all = [slow, medium, fast];
  static const BitcoinTransactionPriority slow =
      BitcoinTransactionPriority(11, title: 'Slow', raw: 0);
  static const BitcoinTransactionPriority medium =
      BitcoinTransactionPriority(90, title: 'Medium', raw: 1);
  static const BitcoinTransactionPriority fast =
      BitcoinTransactionPriority(98, title: 'Fast', raw: 2);

  static BitcoinTransactionPriority deserialize({int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 2:
        return medium;
      case 3:
        return fast;
      default:
        return null;
    }
  }

  final int rate;

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

    return '$label ($rate sat/byte)';
  }
}
