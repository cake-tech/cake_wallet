import "package:cw_core/transaction_info.dart";

export "package:cw_core/transaction_info.dart";

abstract class JsonTransactionInfo extends TransactionInfo {
  JsonTransactionInfo({required super.amount});

  Map<String, dynamic> toJson();
}
