class PaymentRequest {
  PaymentRequest(this.address, this.amount, this.note, this.scheme);

  factory PaymentRequest.fromUri(Uri? uri) {
    var address = "";
    var amount = "";
    var note = "";
    var scheme = "";

    if (uri != null) {
      address = uri.path;
      amount = uri.queryParameters['tx_amount'] ?? uri.queryParameters['amount'] ?? "";
      note = uri.queryParameters['tx_description']
          ?? uri.queryParameters['message'] ?? "";
      scheme = uri.scheme;
    }

    return PaymentRequest(address, amount, note, scheme);
  }

  final String address;
  final String amount;
  final String note;
  final String scheme;
}