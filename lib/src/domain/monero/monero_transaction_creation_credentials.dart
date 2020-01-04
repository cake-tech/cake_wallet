import 'package:cake_wallet/src/domain/common/transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';

class MoneroTransactionCreationCredentials
    extends TransactionCreationCredentials {
  final String address;
  final String paymentId;
  final String amount;
  final TransactionPriority priority;

  MoneroTransactionCreationCredentials(
      {this.address, this.paymentId, this.priority, this.amount});
}