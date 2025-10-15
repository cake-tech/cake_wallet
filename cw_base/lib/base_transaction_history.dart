import 'dart:core';

import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_base/base_transaction_info.dart';

class BaseTransactionHistory extends EVMChainTransactionHistory {
  BaseTransactionHistory({
    required super.walletInfo,
    required super.password,
    required super.encryptionFileUtils,
  });

  @override
  String getTransactionHistoryFileName() => 'base_transactions.json';

  @override
  EVMChainTransactionInfo getTransactionInfo(Map<String, dynamic> val) =>
      BaseTransactionInfo.fromJson(val);
}
