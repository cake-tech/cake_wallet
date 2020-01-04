import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/enumerable_item.dart';

class TransactionPriority extends EnumerableItem<int> with Serializable<int> {
  static const all = [
    TransactionPriority.slow,
    TransactionPriority.regular,
    TransactionPriority.medium,
    TransactionPriority.fast,
    TransactionPriority.fastest
  ];
  static const slow = TransactionPriority(title: 'Slow', raw: 0);
  static const regular = TransactionPriority(title: 'Regular', raw: 1);
  static const medium = TransactionPriority(title: 'Medium', raw: 2);
  static const fast = TransactionPriority(title: 'Fast', raw: 3);
  static const fastest = TransactionPriority(title: 'Fastest', raw: 4);
  static const standart = slow;

  static TransactionPriority deserialize({int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return regular;
      case 2:
        return medium;
      case 3:
        return fast;
      case 4:
        return fastest;
      default:
        return null;
    }
  }

  const TransactionPriority({String title, int raw})
      : super(title: title, raw: raw);

  @override
  String toString() {
    switch (this) {
      case TransactionPriority.slow:
        return S.current.transaction_priority_slow;
      case TransactionPriority.regular:
        return S.current.transaction_priority_regular;
      case TransactionPriority.medium:
        return S.current.transaction_priority_medium;
      case TransactionPriority.fast:
        return S.current.transaction_priority_fast;
      case TransactionPriority.fastest:
        return S.current.transaction_priority_fastest;
      default:
        return '';
    }
  }
}
