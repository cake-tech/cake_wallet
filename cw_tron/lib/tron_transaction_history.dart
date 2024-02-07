import 'dart:core';

import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_tron/tron_transaction_info.dart';

class TronTransactionHistory extends EVMChainTransactionHistory {
  TronTransactionHistory({
    required super.walletInfo,
    required super.password,
  });

  @override
  String getTransactionHistoryFileName() => 'tron_transactions.json';

  @override
  EVMChainTransactionInfo getTransactionInfo(Map<String, dynamic> val) =>
      TronTransactionInfo.fromJson(val);
}
