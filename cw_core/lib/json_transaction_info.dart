import "package:cw_core/transaction_info.dart";

export "package:cw_core/transaction_info.dart";

abstract class JsonTransactionInfo extends TransactionInfo {
  JsonTransactionInfo({
    required super.id,
    required super.amount,
    required super.direction,
    required super.date,
    super.fee,
    super.to,
    super.from,
  });

  Map<String, dynamic> toJson();
}
