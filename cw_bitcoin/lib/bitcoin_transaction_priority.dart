import 'package:cw_core/transaction_priority.dart';
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

  String get units => 'sat';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case BitcoinTransactionPriority.slow:
        label = '${S.current.transaction_priority_slow} ~24hrs';
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

  String labelWithRate(int rate) => '${toString()} ($rate ${units}/byte)';
}

class LitecoinTransactionPriority extends BitcoinTransactionPriority {
  const LitecoinTransactionPriority({String title, int raw})
      : super(title: title, raw: raw);

  static const List<LitecoinTransactionPriority> all = [fast, medium, slow];
  static const LitecoinTransactionPriority slow =
      LitecoinTransactionPriority(title: 'Slow', raw: 0);
  static const LitecoinTransactionPriority medium =
      LitecoinTransactionPriority(title: 'Medium', raw: 1);
  static const LitecoinTransactionPriority fast =
      LitecoinTransactionPriority(title: 'Fast', raw: 2);

  static LitecoinTransactionPriority deserialize({int raw}) {
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
  String get units => 'Latoshi';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case LitecoinTransactionPriority.slow:
        label = S.current.transaction_priority_slow;
        break;
      case LitecoinTransactionPriority.medium:
        label = S.current.transaction_priority_medium;
        break;
      case LitecoinTransactionPriority.fast:
        label = S.current.transaction_priority_fast;
        break;
      default:
        break;
    }

    return label;
  }
}
