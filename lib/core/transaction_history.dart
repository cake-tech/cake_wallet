import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/transaction_info.dart';

abstract class TransactionHistoryBase<TransactionType extends TransactionInfo> {
  TransactionHistoryBase() : _isUpdating = false;

  @observable
  ObservableMap<String, TransactionType> transactions;

  bool _isUpdating;

  @action
  Future<void> update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      final _transactions = await fetchTransactions();
      _transactions.forEach((key, value) => transactions[key] = value);
      _isUpdating = false;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  void updateAsync({void Function() onFinished}) {
    fetchTransactionsAsync(
        (transaction) => transactions[transaction.id] = transaction,
        onFinished: onFinished);
  }

  void fetchTransactionsAsync(
      void Function(TransactionType transaction) onTransactionLoaded,
      {void Function() onFinished});

  Future<Map<String, TransactionType>> fetchTransactions();
}
