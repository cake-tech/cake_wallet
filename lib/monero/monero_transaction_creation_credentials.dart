import 'package:cake_wallet/entities/transaction_creation_credentials.dart';
import 'package:cake_wallet/entities/monero_transaction_priority.dart';
import 'package:cake_wallet/view_model/send/output.dart';

class MoneroTransactionCreationCredentials
    extends TransactionCreationCredentials {
  MoneroTransactionCreationCredentials({this.outputs, this.priority});

  final List<Output> outputs;
  final MoneroTransactionPriority priority;
}
