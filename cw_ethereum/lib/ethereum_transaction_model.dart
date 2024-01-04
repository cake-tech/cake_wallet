import 'package:cw_evm/evm_chain_transaction_model.dart';

class EthereumTransactionModel extends EVMChainTransactionModel {
  EthereumTransactionModel({
    required super.date,
    required super.hash,
    required super.from,
    required super.to,
    required super.amount,
    required super.gasUsed,
    required super.gasPrice,
    required super.contractAddress,
    required super.confirmations,
    required super.blockNumber,
    required super.tokenSymbol,
    required super.tokenDecimal,
    required super.isError,
    
  });
}
