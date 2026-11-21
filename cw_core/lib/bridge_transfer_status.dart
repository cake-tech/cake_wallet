class BridgeTransferStatus {
  const BridgeTransferStatus({this.isDelivered = false, this.isFailed = false, this.message});

  final bool isDelivered;
  final bool isFailed;
  final String? message;
}
