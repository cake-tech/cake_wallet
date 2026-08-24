import 'dart:core';

import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/json_transaction_history.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_nano/nano_transaction_info.dart';

const transactionsHistoryFileName = 'transactions.json';

class NanoTransactionHistory extends JsonTransactionHistory<NanoTransactionInfo> {
  NanoTransactionHistory({
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
  NanoTransactionInfo transactionFromJson(Map<String, dynamic> json) =>
      NanoTransactionInfo.fromJson(json);
}
