import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';

part 'ethereum_transaction_history.g.dart';

class EthereumTransactionHistory = EthereumTransactionHistoryBase
    with _$EthereumTransactionHistory;

abstract class EthereumTransactionHistoryBase
    extends TransactionHistoryBase<EthereumTransactionInfo> with Store {
  EthereumTransactionHistoryBase() {
    transactions = ObservableMap<String, EthereumTransactionInfo>();
  }

  @override
  Future<void> save() async {
    // TODO: implement
  }

  @override
  void addOne(EthereumTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, EthereumTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);
}
