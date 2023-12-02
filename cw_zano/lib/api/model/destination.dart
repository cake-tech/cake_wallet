class Destination {
  final String amount;
  final String address;
  final String assetId;

  Destination(
      {required this.amount, required this.address, required this.assetId});

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        amount: json['amount'] as String,
        address: json['address'] as String,
        assetId: json['asset_id'] as String,
      );

  Map<String, dynamic> toJson() => {
    "amount": amount,
    "address": address,
    "asset_id": assetId,
  };
}
