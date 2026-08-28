import "dart:core";

import "package:cw_core/json_transaction_history.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_tron/tron_transaction_info.dart";

const transactionsHistoryFileName = "tron_transactions.json";

class TronTransactionHistory extends JsonTransactionHistory<TronTransactionInfo> {
  TronTransactionHistory({
    required super.walletInfo,
    required super.password,
    required super.encryptionFileUtils,
  });

  @override
  String get fileName => transactionsHistoryFileName;

  Iterable<TronToken> _tokens = const [];

  @override
  Future<void> prepareForLoad() async {
    _tokens = await TronToken.getAllForWallet(walletInfo.name);
  }

  @override
  TronTransactionInfo transactionFromJson(Map<String, dynamic> json) =>
      TronTransactionInfo.fromJson(json, tokens: _tokens);
}
