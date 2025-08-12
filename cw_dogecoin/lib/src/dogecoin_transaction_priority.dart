import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';

class DogecoinTransactionPriority extends BitcoinTransactionPriority {
  const DogecoinTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<DogecoinTransactionPriority> all = [fast, medium, slow];
  static const DogecoinTransactionPriority slow =
  DogecoinTransactionPriority(title: 'Slow', raw: 0);
  static const DogecoinTransactionPriority medium =
  DogecoinTransactionPriority(title: 'Medium', raw: 1);
  static const DogecoinTransactionPriority fast =
  DogecoinTransactionPriority(title: 'Fast', raw: 2);

  static DogecoinTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for DogecoinTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'koinu';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case DogecoinTransactionPriority.slow:
        label = 'Slow'; // S.current.transaction_priority_slow;
        break;
      case DogecoinTransactionPriority.medium:
        label = 'Medium'; // S.current.transaction_priority_medium;
        break;
      case DogecoinTransactionPriority.fast:
        label = 'Fast'; // S.current.transaction_priority_fast;
        break;
      default:
        break;
    }

    return label;
  }
}

