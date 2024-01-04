import 'package:cw_evm/evm_chain_transaction_info.dart';

class EthereumTransactionInfo extends EVMChainTransactionInfo {
  EthereumTransactionInfo({
    required super.id,
    required super.height,
    required super.ethAmount,
    required super.ethFee,
    required super.direction,
    required super.isPending,
    required super.date,
    required super.confirmations,
    required super.to,
    super.tokenSymbol = "ETH",
    super.exponent = 18,
  });
}
