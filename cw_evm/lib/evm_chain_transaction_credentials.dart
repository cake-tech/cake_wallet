import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';

class EVMChainTransactionCredentials {
  EVMChainTransactionCredentials(
    this.outputs, {
    required this.priority,
    required this.currency,
    this.feeRate,
  });

  final List<OutputInfo> outputs;
  final EVMChainTransactionPriority? priority;
  final int? feeRate;
  final CryptoCurrency currency;
}
