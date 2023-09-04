import 'package:cw_core/transaction_priority.dart';

class BitcoinTransactionPriority extends TransactionPriority {
  const BitcoinTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<BitcoinTransactionPriority> all = [fast, medium, slow];
  static const BitcoinTransactionPriority slow =
      BitcoinTransactionPriority(title: 'Slow', raw: 0);
  static const BitcoinTransactionPriority medium =
      BitcoinTransactionPriority(title: 'Medium', raw: 1);
  static const BitcoinTransactionPriority fast =
      BitcoinTransactionPriority(title: 'Fast', raw: 2);

  static BitcoinTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for BitcoinTransactionPriority deserialize');
    }
  }

  String get units => 'sat';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case BitcoinTransactionPriority.slow:
        label = 'Slow ~24hrs'; // '${S.current.transaction_priority_slow} ~24hrs';
        break;
      case BitcoinTransactionPriority.medium:
        label = 'Medium'; // S.current.transaction_priority_medium;
        break;
      case BitcoinTransactionPriority.fast:
        label = 'Fast'; // S.current.transaction_priority_fast;
        break;
      default:
        break;
    }

    return label;
  }

  String labelWithRate(int rate) => '${toString()} ($rate ${units}/byte)';
}

class LitecoinTransactionPriority extends BitcoinTransactionPriority {
  const LitecoinTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<LitecoinTransactionPriority> all = [fast, medium, slow];
  static const LitecoinTransactionPriority slow =
      LitecoinTransactionPriority(title: 'Slow', raw: 0);
  static const LitecoinTransactionPriority medium =
      LitecoinTransactionPriority(title: 'Medium', raw: 1);
  static const LitecoinTransactionPriority fast =
      LitecoinTransactionPriority(title: 'Fast', raw: 2);

  static LitecoinTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for LitecoinTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'Latoshi';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case LitecoinTransactionPriority.slow:
        label = 'Slow'; // S.current.transaction_priority_slow;
        break;
      case LitecoinTransactionPriority.medium:
        label = 'Medium'; // S.current.transaction_priority_medium;
        break;
      case LitecoinTransactionPriority.fast:
        label = 'Fast'; // S.current.transaction_priority_fast;
        break;
      default:
        break;
    }

    return label;
  }

}
class BitcoinCashTransactionPriority extends BitcoinTransactionPriority {
  const BitcoinCashTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<BitcoinCashTransactionPriority> all = [fast, medium, slow];
  static const BitcoinCashTransactionPriority slow =
  BitcoinCashTransactionPriority(title: 'Slow', raw: 0);
  static const BitcoinCashTransactionPriority medium =
  BitcoinCashTransactionPriority(title: 'Medium', raw: 1);
  static const BitcoinCashTransactionPriority fast =
  BitcoinCashTransactionPriority(title: 'Fast', raw: 2);

  static BitcoinCashTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for BitcoinCashTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'Satoshi';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case BitcoinCashTransactionPriority.slow:
        label = 'Slow'; // S.current.transaction_priority_slow;
        break;
      case BitcoinCashTransactionPriority.medium:
        label = 'Medium'; // S.current.transaction_priority_medium;
        break;
      case BitcoinCashTransactionPriority.fast:
        label = 'Fast'; // S.current.transaction_priority_fast;
        break;
      default:
        break;
    }

    return label;
  }
}

