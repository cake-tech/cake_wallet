import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_core/json_transaction_history.dart";

class ElectrumTransactionHistory extends JsonTransactionHistory<ElectrumTransactionInfo> {
  ElectrumTransactionHistory({
    required super.walletInfo,
    required super.password,
    required super.encryptionFileUtils,
  });

  @override
  String get fileName => "transactions.json";

  @override
  ElectrumTransactionInfo? transactionFromJson(Map<String, dynamic> json) {
    // refactor note:
    // this condition was here before in what i can only assume was a quick-fix to an obscure bug
    // i ain't touching it
    if (json["date"] == 1168650000) {
      return null;
    }
    return ElectrumTransactionInfo.fromJson(json, walletInfo.type);
  }
}
