import 'package:cw_evm/evm_chain_transaction_credentials.dart';

class EthereumTransactionCredentials extends EVMChainTransactionCredentials {
  EthereumTransactionCredentials(
    super.outputs, {
    required super.priority,
    required super.currency,
    super.feeRate,
  });
}
