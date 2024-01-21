class SolanaTransactionModel {
  final String id;

  final String from;

  final String to;

  final double amount;

  // Was the account of this transaction the same as the destination
  final bool isIncomingTransaction;

  // The Program ID of this transaction, e.g, System Program, Token Program...
  final String programId;

  // The DateTime from the UNIX timestamp of the block where the transaction was included
  final DateTime blockTime;

  SolanaTransactionModel({
    required this.id,
    required this.to,
    required this.from,
    required this.amount,
    required this.programId,
    required int blockTimeInInt,
    this.isIncomingTransaction = false,
  }) : blockTime = DateTime.fromMillisecondsSinceEpoch(blockTimeInInt * 1000);

  factory SolanaTransactionModel.fromJson(Map<String, dynamic> json) => SolanaTransactionModel(
        id: json['id'],
        blockTimeInInt: int.parse(json["timeStamp"]) * 1000,
        from: json["from"],
        to: json["to"],
        amount: double.parse(json["value"]),
        programId: json["programId"],
      );
}

class UnsupportedTransaction extends SolanaTransactionModel {
  UnsupportedTransaction(int blockTime)
      : super(
          id: "",
          from: "Unknown",
          to: "Unknown",
          amount: 0.0,
          isIncomingTransaction: false,
          programId: "Unknown",
          blockTimeInInt: blockTime,
        );
}
