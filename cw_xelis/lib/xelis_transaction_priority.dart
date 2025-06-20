import 'package:cw_core/transaction_priority.dart';

class XelisTransactionPriority extends TransactionPriority {
  const XelisTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<XelisTransactionPriority> all = [medium];
  static const XelisTransactionPriority slow = XelisTransactionPriority(title: 'Slow', raw: 1);
  static const XelisTransactionPriority medium =
      XelisTransactionPriority(title: 'Medium', raw: 2);
  static const XelisTransactionPriority fast = XelisTransactionPriority(title: 'Fast', raw: 4);

  static XelisTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 1:
        return slow;
      case 2:
        return medium;
      case 4:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for XelisTransactionPriority deserialize');
    }
  }

  String get units => 'atom';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case XelisTransactionPriority.slow:
        label = 'Slow';
        break;
      case XelisTransactionPriority.medium:
        label = 'Standard';
        break;
      case XelisTransactionPriority.fast:
        label = 'Fast';
        break;
      default:
        break;
    }

    return label;
  }
}