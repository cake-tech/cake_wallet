import 'package:cw_monero/monero_transaction_priority.dart';
import 'package:cw_core/output_info.dart';

class MoneroTransactionCreationCredentials {
  MoneroTransactionCreationCredentials({this.outputs, this.priority});

  final List<OutputInfo> outputs;
  final MoneroTransactionPriority priority;
}
