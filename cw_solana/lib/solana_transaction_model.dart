class SolanaTransactionModel {
  final String id;

  final String from;

  final String to;

  final double amount;

  // If this is an outgoing transaction
  final bool isOutgoingTx;

  // The Program ID of this transaction, e.g, System Program, Token Program...
  final String programId;

  // The DateTime from the UNIX timestamp of the block where the transaction was included
  final DateTime blockTime;

  // The Transaction fee
  final double fee;

  // The token symbol
  final String tokenSymbol;

  SolanaTransactionModel({
    required this.id,
    required this.to,
    required this.from,
    required this.amount,
    required this.programId,
    required int blockTimeInInt,
    this.isOutgoingTx = false,
    required this.tokenSymbol,
    required this.fee,
  }) : blockTime = DateTime.fromMillisecondsSinceEpoch(blockTimeInInt * 1000);

  factory SolanaTransactionModel.fromJson(Map<String, dynamic> json) => SolanaTransactionModel(
        id: json['id'],
        blockTimeInInt: int.parse(json["timeStamp"]) * 1000,
        from: json["from"],
        to: json["to"],
        amount: double.parse(json["value"]),
        programId: json["programId"],
        fee: json['fee'],
        tokenSymbol: json['tokenSymbol'],
      );
}
