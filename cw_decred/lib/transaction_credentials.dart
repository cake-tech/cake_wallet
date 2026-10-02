import 'package:cw_core/coin_control/coin_selection.dart';
import 'package:cw_decred/transaction_priority.dart';
import 'package:cw_core/output_info.dart';

class DecredTransactionCredentials {
  DecredTransactionCredentials(
    this.outputs, {
    required this.priority,
    this.feeRate,
    this.coinSelection = const AllCoinSelection(),
  });

  final List<OutputInfo> outputs;
  final DecredTransactionPriority? priority;
  final int? feeRate;
  final CoinSelection coinSelection;
}
