class AnonpayStatusResponse {
  final String status;
  final double? fiatAmount;
  final String? fiatEquiv;
  final double? amountTo;
  final String coinTo;
  final String address;

  const AnonpayStatusResponse({
    required this.status,
    required this.fiatAmount,
    this.fiatEquiv,
    required this.amountTo,
    required this.coinTo,
    required this.address,
  });
}
