import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_core/output_info.dart';

class BitcoinTransactionCredentials {
  BitcoinTransactionCredentials(this.outputs,
      {required this.priority, this.feeRate, this.useReplaceByFee = true});

  final List<OutputInfo> outputs;
  final BitcoinTransactionPriority? priority;
  final int? feeRate;
  final bool useReplaceByFee;
}
