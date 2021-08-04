import 'package:cake_wallet/entities/transaction_creation_credentials.dart';
import 'package:cake_wallet/entities/monero_transaction_priority.dart';
import 'package:cake_wallet/view_model/send/send_item.dart';

class MoneroTransactionCreationCredentials
    extends TransactionCreationCredentials {
  MoneroTransactionCreationCredentials({this.sendItemList, this.priority});

  final List<SendItem> sendItemList;
  final MoneroTransactionPriority priority;
}
