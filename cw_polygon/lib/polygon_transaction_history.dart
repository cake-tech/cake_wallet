import 'dart:core';

import 'package:cw_evm/evm_chain_transaction_history.dart';

class PolygonTransactionHistory extends EVMChainTransactionHistory {
  PolygonTransactionHistory({
    required super.walletInfo,
    required super.password,
  });

  @override
  String getTransactionHistoryFileName() => 'polygon_transactions.json';
}
