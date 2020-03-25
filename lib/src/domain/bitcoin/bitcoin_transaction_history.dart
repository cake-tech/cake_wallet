import 'dart:core';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';

const bitcoinWalletChannel = MethodChannel('com.cakewallet.cake_wallet/bitcoin-wallet');

Future <List<TransactionInfo>> _getAllTransactions(dynamic _) async {
  final transactionList = await bitcoinWalletChannel.invokeMethod<List<Map<String,String>>>("getTransactions");
  if (transactionList != null) {
    return transactionList.map((elem) => TransactionInfo.fromMap(elem)).toList();
  } else {
    return null;
  }
}

class BitcoinTransactionHistory extends TransactionHistory {
  BitcoinTransactionHistory()
      : _transactions = BehaviorSubject<List<TransactionInfo>>.seeded([]);

  @override
  Observable<List<TransactionInfo>> get transactions => _transactions.stream;

  final BehaviorSubject<List<TransactionInfo>> _transactions;
  bool _isUpdating = false;
  bool _isRefreshing = false;
  bool _needToCheckForRefresh = false;

  @override
  Future<int> count() async => await bitcoinWalletChannel.invokeMethod<int>("countOfTransactions");

  @override
  Future<List<TransactionInfo>> getAll({bool force = false}) async =>
      await _getAllTransactions(null);

  @override
  Future refresh() async {
    if (_isRefreshing) {
      return;
    }

    try {
      _isRefreshing = true;
      await bitcoinWalletChannel.invokeMethod<int>("refresh");
      _isRefreshing = false;
    } on PlatformException catch (e) {
      _isRefreshing = false;
      print(e);
      rethrow;
    }
  }

  @override
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
      rethrow;
    }
  }
}