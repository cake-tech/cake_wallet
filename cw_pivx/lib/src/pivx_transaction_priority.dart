import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';

/// Transparent fee rates in sat/byte, the base Electrum unit. Slow is PIVX
/// Core minRelayTxFee (10000 sat/kB).
class PivxTransactionPriority extends BitcoinTransactionPriority {
  const PivxTransactionPriority(
      {required String title, required int raw, required this.feeRate})
      : super(title: title, raw: raw);

  final int feeRate;

  static const List<PivxTransactionPriority> all = [fast, medium, slow];

  static const PivxTransactionPriority slow =
      PivxTransactionPriority(title: 'Slow', raw: 0, feeRate: 10);
  static const PivxTransactionPriority medium =
      PivxTransactionPriority(title: 'Medium', raw: 1, feeRate: 20);
  static const PivxTransactionPriority fast =
      PivxTransactionPriority(title: 'Fast', raw: 2, feeRate: 50);

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
  String toString() => title;
}
