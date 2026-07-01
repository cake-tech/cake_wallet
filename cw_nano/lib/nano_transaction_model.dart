class NanoTransactionModel {
  final DateTime? date;
  final String hash;
  final bool confirmed;
  final String account;
  final BigInt amount;
  final int height;
  final String type;

  NanoTransactionModel({
    this.date,
    required this.hash,
    required this.height,
    required this.amount,
    required this.confirmed,
    required this.type,
    required this.account,
  });

  factory NanoTransactionModel.fromJson(dynamic json) {
    DateTime? localTimestamp;
    try {
      localTimestamp = DateTime.fromMillisecondsSinceEpoch(
          int.parse(json["local_timestamp"] as String) * 1000);
    } catch (e) {
      localTimestamp = DateTime.now();
    }

    return NanoTransactionModel(
      date: localTimestamp,
      hash: json["hash"] as String,
      height: int.parse(json["height"] as String),
      type: json["type"] as String,
      amount: BigInt.parse(json["amount"] as String),
      account: json["account"] as String,
      confirmed: (json["confirmed"] as String) == "true",
    );
  }
}
