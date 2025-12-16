import 'package:cw_core/transaction_priority.dart';

class MinotariTransactionPriority extends TransactionPriority {
  const MinotariTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<MinotariTransactionPriority> all = [slow, medium, fast];
  static const MinotariTransactionPriority slow =
      MinotariTransactionPriority(title: 'Slow', raw: 0);
  static const MinotariTransactionPriority medium =
      MinotariTransactionPriority(title: 'Medium', raw: 1);
  static const MinotariTransactionPriority fast =
      MinotariTransactionPriority(title: 'Fast', raw: 2);

  static MinotariTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected Minotari transaction priority: $raw');
    }
  }

  String get units => 'sat/vB'; // TODO: Determine Minotari fee units

  @override
  String toString() {
    var label = '';

    switch (this) {
      case MinotariTransactionPriority.slow:
        label = 'Slow';
        break;
      case MinotariTransactionPriority.medium:
        label = 'Medium';
        break;
      case MinotariTransactionPriority.fast:
        label = 'Fast';
        break;
      default:
        break;
    }

    return label;
  }
}
