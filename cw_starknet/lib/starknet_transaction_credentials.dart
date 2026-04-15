import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_priority.dart';

class StarknetTransactionCredentials {
  StarknetTransactionCredentials(
    this.outputs, {
    required this.currency,
    this.priority,
  });

  final List<OutputInfo> outputs;
  final CryptoCurrency currency;
  final TransactionPriority? priority;
}
