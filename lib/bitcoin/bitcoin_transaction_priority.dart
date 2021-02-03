import 'package:cake_wallet/entities/transaction_priority.dart';

class BitcoinTransactionPriority extends TransactionPriority {
  const BitcoinTransactionPriority(this.rate, {String title, int raw})
      : super(title: title, raw: raw);

  static const List<BitcoinTransactionPriority> all = [slow, medium, fast];
  static const BitcoinTransactionPriority slow = BitcoinTransactionPriority(11, title: 'Slow', raw: 0);
  static const BitcoinTransactionPriority medium = BitcoinTransactionPriority(90, title: 'Medium', raw: 1);
  static const BitcoinTransactionPriority fast = BitcoinTransactionPriority(98, title: 'Fast', raw: 2);

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
  String toString() => '$rate sat/byte';
}
