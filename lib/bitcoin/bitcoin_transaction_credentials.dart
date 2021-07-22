import 'package:cake_wallet/bitcoin/bitcoin_transaction_priority.dart';
import 'package:cake_wallet/view_model/send/send_item.dart';

class BitcoinTransactionCredentials {
  BitcoinTransactionCredentials(this.sendItemList, this.priority);

  final List<SendItem> sendItemList;
  BitcoinTransactionPriority priority;
}
