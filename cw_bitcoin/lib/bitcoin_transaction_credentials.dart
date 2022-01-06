import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_core/output_info.dart';

class BitcoinTransactionCredentials {
  BitcoinTransactionCredentials(this.outputs, this.priority);

  final List<OutputInfo> outputs;
  BitcoinTransactionPriority priority;
}
