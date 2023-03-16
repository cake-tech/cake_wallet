import 'package:cw_core/output_info.dart';
import 'package:cw_ethereum/ethereum_transaction_priority.dart';

class EthereumTransactionCredentials {
  EthereumTransactionCredentials(this.outputs, {required this.priority, this.feeRate});

  final List<OutputInfo> outputs;
  final EthereumTransactionPriority? priority;
  final int? feeRate;
}
