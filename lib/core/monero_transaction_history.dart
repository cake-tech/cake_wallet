import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_monero/transaction_history.dart'
    as monero_transaction_history;
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/domain/monero/monero_transaction_info.dart';

part 'monero_transaction_history.g.dart';

List<TransactionInfo> _getAllTransactions(dynamic _) =>
    monero_transaction_history
        .getAllTransations()
        .map((row) => MoneroTransactionInfo.fromRow(row))
        .toList();

class MoneroTransactionHistory = MoneroTransactionHistoryBase
    with _$MoneroTransactionHistory;

abstract class MoneroTransactionHistoryBase
    extends TranasctionHistoryBase<TransactionInfo> with Store {
  @override
  Future<List<TransactionInfo>> fetchTransactions() async {
    monero_transaction_history.refreshTransactions();
    return _getAllTransactions(null);
  }
}
