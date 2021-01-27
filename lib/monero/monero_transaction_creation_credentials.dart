import 'package:cake_wallet/entities/transaction_creation_credentials.dart';
import 'package:cake_wallet/entities/monero_transaction_priority.dart';

class MoneroTransactionCreationCredentials
    extends TransactionCreationCredentials {
  MoneroTransactionCreationCredentials(
      {this.address, this.paymentId, this.priority, this.amount});

  final String address;
  final String paymentId;
  final String amount;
  final MoneroTransactionPriority priority;
}
