import "dart:core";

import "package:cw_core/json_transaction_history.dart";
import "package:cw_nano/nano_transaction_info.dart";

const transactionsHistoryFileName = "transactions.json";

class NanoTransactionHistory extends JsonTransactionHistory<NanoTransactionInfo> {
  NanoTransactionHistory({
    required super.walletInfo,
    required super.password,
    required super.encryptionFileUtils,
  });

  @override
  String get fileName => transactionsHistoryFileName;

  @override
  NanoTransactionInfo transactionFromJson(Map<String, dynamic> json) =>
      NanoTransactionInfo.fromJson(json);
}
