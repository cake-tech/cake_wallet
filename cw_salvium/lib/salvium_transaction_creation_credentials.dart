import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/output_info.dart';

class SalviumTransactionCreationCredentials {
  SalviumTransactionCreationCredentials({
    required this.outputs,
    required this.priority,
    required this.assetType});

  final List<OutputInfo> outputs;
  final MoneroTransactionPriority priority;
  final String assetType;
}
