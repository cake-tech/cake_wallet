import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/monero_transaction_priority.dart";
import "package:cw_core/output_info.dart";

class MoneroTransactionCreationCredentials {
  MoneroTransactionCreationCredentials({
    required this.outputs,
    required this.priority,
    this.coinSelection = const AllCoinSelection(),
  });

  final List<OutputInfo> outputs;
  final MoneroTransactionPriority priority;
  final CoinSelection coinSelection;
}
