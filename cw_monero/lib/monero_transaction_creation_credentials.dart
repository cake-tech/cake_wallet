import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/output_info.dart';

class MoneroTransactionCreationCredentials {
  MoneroTransactionCreationCredentials({required this.outputs, required this.priority});

  final List<OutputInfo> outputs;
  final MoneroTransactionPriority priority;
}
