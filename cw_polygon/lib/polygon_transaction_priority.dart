import 'package:cw_ethereum/ethereum_transaction_priority.dart';

class PolygonTransactionPriority extends EthereumTransactionPriority {
  const PolygonTransactionPriority({required String title, required int raw, required int tip})
      : super(title: title, raw: raw, tip: tip);

  static const List<PolygonTransactionPriority> all = [fast, medium, slow];
  static const PolygonTransactionPriority slow =
      PolygonTransactionPriority(title: 'slow', raw: 0, tip: 1);
  static const PolygonTransactionPriority medium =
      PolygonTransactionPriority(title: 'Medium', raw: 1, tip: 2);
  static const PolygonTransactionPriority fast =
      PolygonTransactionPriority(title: 'Fast', raw: 2, tip: 4);

  static PolygonTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for PolygonTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'gas';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case PolygonTransactionPriority.slow:
        label = 'Slow';
        break;
      case PolygonTransactionPriority.medium:
        label = 'Medium';
        break;
      case PolygonTransactionPriority.fast:
        label = 'Fast';
        break;
      default:
        break;
    }

    return label;
  }
}
