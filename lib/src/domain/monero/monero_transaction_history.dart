import 'dart:core';
import 'package:cake_wallet/src/domain/monero/monero_transaction_info.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cw_monero/transaction_history.dart'
    as monero_transaction_history;
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';

List<TransactionInfo> _getAllTransactions(dynamic _) =>
    monero_transaction_history
        .getAllTransations()
        .map((row) => MoneroTransactionInfo.fromRow(row))
        .toList();

class MoneroTransactionHistory extends TransactionHistory {
  MoneroTransactionHistory()
      : _transactions = BehaviorSubject<List<TransactionInfo>>.seeded([]);

  @override
  Observable<List<TransactionInfo>> get transactions => _transactions.stream;

  final BehaviorSubject<List<TransactionInfo>> _transactions;
  bool _isUpdating = false;
  bool _isRefreshing = false;
  bool _needToCheckForRefresh = false;

  @override
  Future update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      _transactions.value = await getAll(force: true);
      _isUpdating = false;

      if (!_needToCheckForRefresh) {
        _needToCheckForRefresh = true;
      }
    } catch (e) {
      _isUpdating = false;
      print(e);
      rethrow;
    }
  }

  @override
  Future<List<TransactionInfo>> getAll({bool force = false}) async {
    await refresh();
    return _getAllTransactions(null);
  }

  Future refresh() async {
    if (_isRefreshing) {
      return;
    }

    try {
      _isRefreshing = true;
      monero_transaction_history.refreshTransactions();
      _isRefreshing = false;
    } on PlatformException catch (e) {
      _isRefreshing = false;
      print(e);
      rethrow;
    }
  }
}
