import 'package:cw_core/transaction_priority.dart';

class EthereumTransactionPriority extends TransactionPriority {
  final int value;

  const EthereumTransactionPriority({required String title, required int raw, required this.value})
      : super(title: title, raw: raw);

  static const List<EthereumTransactionPriority> all = [fast, medium, slow];
  static const EthereumTransactionPriority slow =
      EthereumTransactionPriority(title: 'Slow', raw: 0, value: 2);
  static const EthereumTransactionPriority medium =
      EthereumTransactionPriority(title: 'Medium', raw: 1, value: 5);
  static const EthereumTransactionPriority fast =
      EthereumTransactionPriority(title: 'Fast', raw: 2, value: 10);

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
        label = 'slow';
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
