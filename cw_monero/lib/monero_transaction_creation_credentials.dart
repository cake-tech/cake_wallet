//import 'package:cake_wallet/entities/transaction_creation_credentials.dart';
import 'package:cw_monero/monero_transaction_priority.dart';
//import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/output_info.dart';

class MoneroTransactionCreationCredentials {
  MoneroTransactionCreationCredentials({this.outputs, this.priority});

  final List<OutputInfo> outputs;
  final MoneroTransactionPriority priority;
}
