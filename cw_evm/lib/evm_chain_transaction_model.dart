class EVMChainTransactionModel {
  final DateTime date;
  final String hash;
  final String from;
  final String to;
  final BigInt amount;
  final int gasUsed;
  final BigInt gasPrice;
  final String contractAddress;
  final int confirmations;
  final int blockNumber;
  final String? tokenSymbol;
  final int? tokenDecimal;
  final bool isError;
  final String input;
  final int chainId;
  String? evmSignatureName;

  EVMChainTransactionModel({
    required this.date,
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.gasUsed,
    required this.gasPrice,
    required this.contractAddress,
    required this.confirmations,
    required this.blockNumber,
    required this.tokenSymbol,
    required this.tokenDecimal,
    required this.isError,
    required this.input,
    required this.chainId,
    this.evmSignatureName,
  });

  factory EVMChainTransactionModel.fromJson(
          Map<String, dynamic> json, String defaultSymbol, int chainId) =>
      EVMChainTransactionModel(
        date: DateTime.fromMillisecondsSinceEpoch(int.parse(json["timeStamp"] as String) * 1000),
        hash: json["hash"] as String? ?? "",
        from: json["from"] as String? ?? "",
        to: json["to"] as String? ?? "",
        amount: BigInt.parse(json["value"] as String? ?? "0"),
        gasUsed: int.parse(json["gasUsed"] as String? ?? "0"),
        gasPrice: BigInt.parse(json["gasPrice"] as String? ?? "0"),
        contractAddress: json["contractAddress"] as String? ?? "",
        confirmations: int.parse(json["confirmations"] as String? ?? "0"),
        blockNumber: int.parse(json["blockNumber"] as String? ?? "0"),
        tokenSymbol: json["tokenSymbol"] as String? ?? defaultSymbol,
        tokenDecimal: int.tryParse(json["tokenDecimal"] as String? ?? ""),
        isError: json["isError"] == "1",
        input: json["input"] as String? ?? "",
        evmSignatureName: json["evmSignatureName"] as String?,
        chainId: chainId,
      );
}
