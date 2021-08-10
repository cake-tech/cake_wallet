import 'package:cake_wallet/bitcoin/bitcoin_transaction_priority.dart';
import 'package:cake_wallet/view_model/send/output.dart';

class BitcoinTransactionCredentials {
  BitcoinTransactionCredentials(this.outputs, this.priority);

  final List<Output> outputs;
  BitcoinTransactionPriority priority;
}
