import 'package:cw_core/transaction_priority.dart';

class DummyTransactionPriority extends TransactionPriority {
  const DummyTransactionPriority({required super.title, required super.raw});

  static const List<DummyTransactionPriority> all = [slow, medium, fast];

  static const slow = DummyTransactionPriority(title: 'Slow', raw: 0);
  static const medium = DummyTransactionPriority(title: 'Medium', raw: 1);
  static const fast = DummyTransactionPriority(title: 'Fast', raw: 2);

  static DummyTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0: return slow;
      case 1: return medium;
      case 2: return fast;
      default: throw Exception('Unexpected token: $raw for DummyTransactionPriority deserialize');
    }
  }
}