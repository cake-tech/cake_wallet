class AnonpayStatusResponse {
  final String status;
  final double? fiatAmount;
  final String? fiatEquiv;
  final double? amountTo;
  final String coinTo;
  final String address;

  const AnonpayStatusResponse({
    required this.status,
    this.fiatAmount,
    this.fiatEquiv,
    this.amountTo,
    required this.coinTo,
    required this.address,
  });
}
