import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_monero/transaction_history.dart'
    as monero_transaction_history;
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/domain/monero/monero_transaction_info.dart';

part 'monero_transaction_history.g.dart';

List<MoneroTransactionInfo> _getAllTransactions(dynamic _) =>
    monero_transaction_history
        .getAllTransations()
        .map((row) => MoneroTransactionInfo.fromRow(row))
        .toList();

class MoneroTransactionHistory = MoneroTransactionHistoryBase
    with _$MoneroTransactionHistory;

abstract class MoneroTransactionHistoryBase
    extends TransactionHistoryBase<MoneroTransactionInfo> with Store {
  MoneroTransactionHistoryBase() {
    transactions = ObservableMap<String, MoneroTransactionInfo>();
  }

  @override
  Future<Map<String, MoneroTransactionInfo>> fetchTransactions() async {
    monero_transaction_history.refreshTransactions();
    return _getAllTransactions(null).fold<Map<String, MoneroTransactionInfo>>(
        <String, MoneroTransactionInfo>{},
        (Map<String, MoneroTransactionInfo> acc, MoneroTransactionInfo tx) {
      acc[tx.id] = tx;
      return acc;
    });
  }

  @override
  void updateAsync({void Function() onFinished}) {
    fetchTransactionsAsync(
        (transaction) => transactions[transaction.id] = transaction,
        onFinished: onFinished);
  }

  @override
  void fetchTransactionsAsync(
      void Function(MoneroTransactionInfo transaction) onTransactionLoaded,
      {void Function() onFinished}) {}
}
