import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';

/// PIVX transaction priority levels. Fees from PIVX Core: minRelayTxFee
/// 10000 sat/kB, dustRelayFee 30000 sat/kB. Shielded txs require 100x the
/// minimum relay fee.
class PivxTransactionPriority extends BitcoinTransactionPriority {
  const PivxTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<PivxTransactionPriority> all = [fast, medium, slow];

  static const PivxTransactionPriority slow =
      PivxTransactionPriority(title: 'Slow', raw: 0);
  static const PivxTransactionPriority medium =
      PivxTransactionPriority(title: 'Medium', raw: 1);
  static const PivxTransactionPriority fast =
      PivxTransactionPriority(title: 'Fast', raw: 2);

  static PivxTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception(
            'Unexpected token: $raw for PivxTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'sat/kB';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case PivxTransactionPriority.slow:
        label = 'Slow';
        break;
      case PivxTransactionPriority.medium:
        label = 'Medium';
        break;
      case PivxTransactionPriority.fast:
        label = 'Fast';
        break;
      default:
        break;
    }

    return label;
  }

  /// Fee rate in sat/kB: Slow 10000 (minRelayTxFee), Medium 20000, Fast 50000.
  int get feeRate {
    switch (this) {
      case PivxTransactionPriority.slow:
        return 10000; // minRelayTxFee
      case PivxTransactionPriority.medium:
        return 20000;
      case PivxTransactionPriority.fast:
        return 50000;
      default:
        return 10000;
    }
  }
}
