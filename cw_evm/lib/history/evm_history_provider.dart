import "package:cw_evm/evm_chain_transaction_model.dart";

abstract class EvmHistoryProvider {
  String get name;

  bool covers(int chainId);

  Future<List<EVMChainTransactionModel>> transactions(int chainId, String address);

  Future<List<EVMChainTransactionModel>> tokenTransfers(
    int chainId,
    String address,
    String contractAddress,
  );

  Future<List<EVMChainTransactionModel>> internalTransactions(int chainId, String address);
}
