import 'dart:core';

import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_gnosis/gnosis_transaction_info.dart';

class GnosisTransactionHistory extends EVMChainTransactionHistory {
  GnosisTransactionHistory({
    required super.walletInfo,
    required super.password,
    required super.encryptionFileUtils,
  });

  @override
  String getTransactionHistoryFileName() => 'gnosis_transactions.json';

  @override
  EVMChainTransactionInfo getTransactionInfo(Map<String, dynamic> val) =>
      GnosisTransactionInfo.fromJson(val);
}
