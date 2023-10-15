import 'package:cw_core/output_info.dart';

import 'dummy_transaction_priority.dart';

class DummyTransactionCreationCredentials {
  final List<OutputInfo> outputs;
  final DummyTransactionPriority? priority;

  DummyTransactionCreationCredentials({required this.outputs, this.priority});
}
