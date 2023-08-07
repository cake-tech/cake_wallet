import 'package:cw_core/transaction_priority.dart';

class EthereumTransactionPriority extends TransactionPriority {
  final int tip;

  const EthereumTransactionPriority({required String title, required int raw, required this.tip})
      : super(title: title, raw: raw);

  static const List<EthereumTransactionPriority> all = [fast, medium, slow];
  static const EthereumTransactionPriority slow =
      EthereumTransactionPriority(title: 'slow', raw: 0, tip: 1);
  static const EthereumTransactionPriority medium =
      EthereumTransactionPriority(title: 'Medium', raw: 1, tip: 2);
  static const EthereumTransactionPriority fast =
      EthereumTransactionPriority(title: 'Fast', raw: 2, tip: 4);

  static EthereumTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for EthereumTransactionPriority deserialize');
    }
  }

  String get units => 'gas';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case EthereumTransactionPriority.slow:
        label = 'Slow';
        break;
      case EthereumTransactionPriority.medium:
        label = 'Medium';
        break;
      case EthereumTransactionPriority.fast:
        label = 'Fast';
        break;
      default:
        break;
    }

    return label;
  }
}
