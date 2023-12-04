import 'package:cw_ethereum/ethereum_transaction_model.dart';

class PolygonTransactionModel extends EthereumTransactionModel {
  PolygonTransactionModel({
    required DateTime date,
    required String hash,
    required String from,
    required String to,
    required BigInt amount,
    required int gasUsed,
    required BigInt gasPrice,
    required String contractAddress,
    required int confirmations,
    required int blockNumber,
    required String? tokenSymbol,
    required int? tokenDecimal,
    required bool isError,
  }) : super(
          amount: amount,
          date: date,
          hash: hash,
          from: from,
          to: to,
          gasPrice: gasPrice,
          gasUsed: gasUsed,
          confirmations: confirmations,
          contractAddress: contractAddress,
          blockNumber: blockNumber,
          tokenDecimal: tokenDecimal,
          tokenSymbol: tokenSymbol,
          isError: isError,
        );

  factory PolygonTransactionModel.fromJson(Map<String, dynamic> json) => PolygonTransactionModel(
        date: DateTime.fromMillisecondsSinceEpoch(int.parse(json["timeStamp"]) * 1000),
        hash: json["hash"],
        from: json["from"],
        to: json["to"],
        amount: BigInt.parse(json["value"]),
        gasUsed: int.parse(json["gasUsed"]),
        gasPrice: BigInt.parse(json["gasPrice"]),
        contractAddress: json["contractAddress"],
        confirmations: int.parse(json["confirmations"]),
        blockNumber: int.parse(json["blockNumber"]),
        tokenSymbol: json["tokenSymbol"] ?? "MATIC",
        tokenDecimal: int.tryParse(json["tokenDecimal"] ?? ""),
        isError: json["isError"] == "1",
      );
}
