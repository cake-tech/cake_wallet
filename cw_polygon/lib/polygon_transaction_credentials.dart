import 'package:cw_evm/evm_chain_transaction_credentials.dart';

class PolygonTransactionCredentials extends EVMChainTransactionCredentials {
  PolygonTransactionCredentials(
    super.outputs, {
    required super.priority,
    required super.currency,
    super.feeRate,
  });

}
