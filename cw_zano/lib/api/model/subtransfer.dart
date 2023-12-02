class Subtransfer {
  final int amount;
  final String assetId;
  final bool isIncome;

  Subtransfer(
      {required this.amount, required this.assetId, required this.isIncome});

  factory Subtransfer.fromJson(Map<String, dynamic> json) => Subtransfer(
        amount: json['amount'] as int,
        assetId: json['asset_id'] as String,
        isIncome: json['is_income'] as bool,
      );
}
