import 'dart:core';

import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_arbitrum/arbitrum_transaction_info.dart';

class ArbitrumTransactionHistory extends EVMChainTransactionHistory {
  ArbitrumTransactionHistory({
    required super.walletInfo,
    required super.password,
    required super.encryptionFileUtils,
  });

  @override
  String getTransactionHistoryFileName() => 'arbitrum_transactions.json';

  @override
  EVMChainTransactionInfo getTransactionInfo(Map<String, dynamic> val) =>
      ArbitrumTransactionInfo.fromJson(val);
}
