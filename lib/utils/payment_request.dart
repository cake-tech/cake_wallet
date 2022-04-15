class PaymentRequest {
  PaymentRequest(this.address, this.amount);

  factory PaymentRequest.fromUri(Uri uri) {
    var address = "";
    var amount = "";

    if (uri != null) {
      address = uri.path;
      amount = uri.queryParameters['tx_amount'] ?? uri.queryParameters['amount'] ?? "";
    }

    return PaymentRequest(address, amount);
  }

  final String address;
  final String amount;
}