import "package:cw_tron/tron_transaction_model.dart";

abstract class TronTransactionsApi {
  Future<List<TronTransactionModel>> getTransactions(String address);

  Future<List<TronTRC20TransactionModel>> getTrc20Transactions(String address);
}
