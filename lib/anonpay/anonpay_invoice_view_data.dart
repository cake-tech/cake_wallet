class AnonpayInvoiceViewData {
  final String invoiceId;
  final AnonpayStatusData statusData;
  final String clearnetUrl;
  final String onionUrl;
  final String clearnetStatusUrl;
  final String onionStatusUrl;

  const AnonpayInvoiceViewData({
    required this.invoiceId,
    required this.statusData,
    required this.clearnetUrl,
    required this.onionUrl,
    required this.clearnetStatusUrl,
    required this.onionStatusUrl,
  });
}

class AnonpayStatusData {
  final String transactionId;
  final String status;
  final String fiatAmount;
  final String? fiatEquiv;
  final double amountTo;
  final String coinTo;
  final String address;

  const AnonpayStatusData({
    required this.transactionId,
    required this.status,
    required this.fiatAmount,
    this.fiatEquiv,
    required this.amountTo,
    required this.coinTo,
    required this.address,
  });
}
