import 'dart:core';

import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/json_transaction_history.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_evm/utils/evm_chain_utils.dart';

class EVMChainTransactionHistory extends JsonTransactionHistory<EVMChainTransactionInfo> {
  EVMChainTransactionHistory({
    required WalletInfo walletInfo,
    required String password,
    required EncryptionFileUtils encryptionFileUtils,
    required this.getCurrentChainId,
  }) : super(
          walletInfo: walletInfo,
          password: password,
          encryptionFileUtils: encryptionFileUtils,
        );

  /// Lets the history resolve the file — and the chain filter — for whichever
  /// chain the wallet is currently on.
  final int Function() getCurrentChainId;

  @override
  String get fileName => EVMChainUtils.getTransactionHistoryFileName(getCurrentChainId());

  @override
  EVMChainTransactionInfo transactionFromJson(Map<String, dynamic> json) =>
      EVMChainTransactionInfo.fromJson(json, getCurrentChainId());

  /// Keeps one chain's file from ever picking up another chain's transactions.
  @override
  bool shouldPersist(EVMChainTransactionInfo transaction) =>
      transaction.chainId == getCurrentChainId();

  @override
  void addOne(EVMChainTransactionInfo transaction) {
    if (transaction.chainId == getCurrentChainId()) put(transaction.id, transaction);
  }

  @override
  void addMany(Map<String, EVMChainTransactionInfo> transactions) {
    final currentChainId = getCurrentChainId();

    // Drop anything left over from another chain before taking the new batch on,
    // so switching chains can't leave foreign transactions in the map.
    removeWhere((_, transaction) => transaction.chainId != currentChainId);

    for (final entry in transactions.entries) {
      if (entry.value.chainId == currentChainId) put(entry.key, entry.value);
    }
  }
}
