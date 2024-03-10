class Receive {
  final int amount;
  final String assetId;
  final int index;

  Receive({required this.amount, required this.assetId, required this.index});

  factory Receive.fromJson(Map<String, dynamic> json) => Receive(
        amount: json['amount'] as int? ?? 0,
        assetId: json['asset_id'] as String? ?? '',
        index: json['index'] as int? ?? 0,
      );
}
