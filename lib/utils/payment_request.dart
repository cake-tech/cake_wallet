class PaymentRequest {
  PaymentRequest(this.address, this.amount, {this.scheme});

  factory PaymentRequest.fromUri(Uri uri) {
    var address = "";
    var amount = "";
    var scheme = "";

    if (uri != null) {
      address = uri.path;
      amount = uri.queryParameters['tx_amount'] ?? uri.queryParameters['amount'] ?? "";
      scheme = uri.scheme;
    }

    return PaymentRequest(address, amount, scheme: scheme);
  }

  final String address;
  final String amount;
  final String scheme;
}