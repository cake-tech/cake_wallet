class TronTransactionModel {
  final DateTime date;
  final String hash;
  final String from;
  final String to;
  final BigInt amount;
  final int gasUsed;
  final BigInt gasPrice;
  final String contractAddress;
  final String? tokenSymbol;
  final int? tokenDecimal;
  final bool isError;

  TronTransactionModel({
    required this.date,
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.gasUsed,
    required this.gasPrice,
    required this.contractAddress,
    required this.tokenSymbol,
    required this.tokenDecimal,
    required this.isError,
  });

  factory TronTransactionModel.fromJson(Map<String, dynamic> json, String defaultSymbol) =>
      TronTransactionModel(
        date: DateTime.fromMillisecondsSinceEpoch(int.parse(json["timeStamp"]) * 1000),
        hash: json["hash"],
        from: json["from"],
        to: json["to"],
        amount: BigInt.parse(json["value"]),
        gasUsed: int.parse(json["gasUsed"]),
        gasPrice: BigInt.parse(json["gasPrice"]),
        contractAddress: json["contractAddress"],
        tokenSymbol: json["tokenSymbol"] ?? defaultSymbol,
        tokenDecimal: int.tryParse(json["tokenDecimal"] ?? ""),
        isError: json["isError"] == "1",
      );
}
