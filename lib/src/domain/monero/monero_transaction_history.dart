import 'dart:core';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cw_monero/transaction_history.dart' as moneroTransactionHistory;
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';

List<TransactionInfo> _getAllTransactions(_) => moneroTransactionHistory
    .getAllTransations()
    .map((row) => TransactionInfo.fromRow(row))
    .toList();

class MoneroTransactionHistory extends TransactionHistory {
  get transactions => _transactions.stream;
  BehaviorSubject<List<TransactionInfo>> _transactions;

  bool _isUpdating = false;
  bool _isRefreshing = false;
  bool _needToCheckForRefresh = false;

  MoneroTransactionHistory()
      : _transactions = BehaviorSubject<List<TransactionInfo>>.seeded([]);

  Future update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      await refresh();
      _transactions.value = await getAll(force: true);
      _isUpdating = false;

      if (!_needToCheckForRefresh) {
        _needToCheckForRefresh = true;
      }
    } catch (e) {
      _isUpdating = false;
      print(e);
      throw e;
    }
  }

  Future<List<TransactionInfo>> getAll({bool force = false}) async =>
      _getAllTransactions(null);

  Future<int> count() async => moneroTransactionHistory.countOfTransactions();

  Future refresh() async {
    if (_isRefreshing) {
      return;
    }

    try {
      _isRefreshing = true;
      moneroTransactionHistory.refreshTransactions();
      _isRefreshing = false;
    } on PlatformException catch (e) {
      _isRefreshing = false;
      print(e);
      throw e;
    }
  }
}
