class Destination {
  final String amount;
  final String address;
  final String assetId;

  Destination({required this.amount, required this.address, required this.assetId});

  Map<String, dynamic> toJson() => {
    "amount": amount,
    "address": address,
    "asset_id": assetId,
  };
}

class TransferParams {
  final List<Destination> destinations;
  final int fee;
  final int mixin;
  final String paymentId;
  final String comment;
  final bool pushPayer;
  final bool hideReceiver;

  TransferParams({required this.destinations, required this.fee, required this.mixin, required this.paymentId, required this.comment, required this.pushPayer, required this.hideReceiver});

  Map<String, dynamic> toJson() => {
    "destinations": destinations,
    "fee": fee,
    "mixin": mixin,
    "payment_id": paymentId,
    "comment": comment,
    "push_payer": pushPayer,
    "hide_receiver": hideReceiver,
  };
}

class GetRecentTxsAndInfoParams {
  final int offset;
  final int count;
  final bool updateProvisionInfo;

  GetRecentTxsAndInfoParams({required this.offset, required this.count, required this.updateProvisionInfo});

  Map<String, dynamic> toJson() => {
    "offset": offset,
    "count": count,
    "update_provision_info": updateProvisionInfo,
  };
}