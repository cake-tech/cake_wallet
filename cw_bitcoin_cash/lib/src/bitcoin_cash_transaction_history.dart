import 'dart:core';

import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

import 'bitcoin_cash_transaction_info.dart';

part 'bitcoin_cash_transaction_history.g.dart';

class BitcoinCashTransactionHistory = BitcoinCashTransactionHistoryBase
    with _$BitcoinCashTransactionHistory;

abstract class BitcoinCashTransactionHistoryBase
    extends TransactionHistoryBase<BitcoinCashTransactionInfo> with Store {
  BitcoinCashTransactionHistoryBase({required this.walletInfo, required String password})
      : _password = password,
        _height = 0 {
    transactions = ObservableMap<String, BitcoinCashTransactionInfo>();
  }

  final WalletInfo walletInfo;
  String _password;
  int _height;

  @override
  Future<void> save() async {
    // TODO: implement
  }

  @override
  void addOne(BitcoinCashTransactionInfo transaction) => transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, BitcoinCashTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);
}
