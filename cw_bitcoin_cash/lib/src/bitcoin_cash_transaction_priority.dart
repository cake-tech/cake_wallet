import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';

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
        throw Exception('Unexpected token: $raw for BitcoinTransactionPriority deserialize');
    }
  }

  String get units => 'sat';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case BitcoinCashTransactionPriority.slow:
        label = 'Slow ~24hrs'; // '${S.current.transaction_priority_slow} ~24hrs';
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

  String labelWithRate(int rate) => '${toString()} ($rate ${units}/byte)';
}
