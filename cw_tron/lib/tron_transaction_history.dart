import 'dart:core';

import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/json_transaction_history.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_tron/tron_transaction_info.dart';

const transactionsHistoryFileName = 'tron_transactions.json';

class TronTransactionHistory extends JsonTransactionHistory<TronTransactionInfo> {
  TronTransactionHistory({
    required WalletInfo walletInfo,
    required String password,
    required EncryptionFileUtils encryptionFileUtils,
  }) : super(
          walletInfo: walletInfo,
          password: password,
          encryptionFileUtils: encryptionFileUtils,
        );

  @override
  String get fileName => transactionsHistoryFileName;

  @override
  TronTransactionInfo transactionFromJson(Map<String, dynamic> json) =>
      TronTransactionInfo.fromJson(json);
}
