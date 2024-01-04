import 'package:cw_evm/evm_chain_exceptions.dart';

class EthereumTransactionCreationException extends EVMChainTransactionCreationException {
  EthereumTransactionCreationException(super.currency);
}
