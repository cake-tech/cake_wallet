import 'dart:core';

import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/json_transaction_history.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_solana/solana_transaction_info.dart';

const transactionsHistoryFileName = 'solana_transactions.json';

class SolanaTransactionHistory extends JsonTransactionHistory<SolanaTransactionInfo> {
  SolanaTransactionHistory({
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
  SolanaTransactionInfo transactionFromJson(Map<String, dynamic> json) =>
      SolanaTransactionInfo.fromJson(json);
}
