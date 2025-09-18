import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';

class DigibyteTransactionPriority extends BitcoinTransactionPriority {
  const DigibyteTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<DigibyteTransactionPriority> all = [fast, medium, slow];
  static const DigibyteTransactionPriority slow =
      DigibyteTransactionPriority(title: 'Slow', raw: 0);
  static const DigibyteTransactionPriority medium =
      DigibyteTransactionPriority(title: 'Medium', raw: 1);
  static const DigibyteTransactionPriority fast =
      DigibyteTransactionPriority(title: 'Fast', raw: 2);

  static DigibyteTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for DigibyteTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'sat';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case DigibyteTransactionPriority.slow:
        label = 'Slow'; // S.current.transaction_priority_slow;
        break;
      case DigibyteTransactionPriority.medium:
        label = 'Medium'; // S.current.transaction_priority_medium;
        break;
      case DigibyteTransactionPriority.fast:
        label = 'Fast'; // S.current.transaction_priority_fast;
        break;
      default:
        break;
    }

    return label;
  }
}

