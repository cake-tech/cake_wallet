import "package:cw_core/erc20_token.dart";
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

  /// Function to get the current chain ID (allows transaction history to use correct file)
  final int Function() getCurrentChainId;


  @override
  String get fileName => EVMChainUtils.getTransactionHistoryFileName(getCurrentChainId());

  Iterable<Erc20Token> _tokens = const [];

  @override
  Future<void> prepareForLoad() async {
    _tokens = await Erc20Token.getAllForWallet(walletInfo.name, getCurrentChainId());
  }

  @override
  EVMChainTransactionInfo transactionFromJson(Map<String, dynamic> json) =>
      EVMChainTransactionInfo.fromJson(json, getCurrentChainId(), tokens: _tokens);

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

    removeWhere((_, transaction) => transaction.chainId != currentChainId);

    for (final entry in transactions.entries) {
      if (entry.value.chainId == currentChainId) put(entry.key, entry.value);
    }
  }
}
