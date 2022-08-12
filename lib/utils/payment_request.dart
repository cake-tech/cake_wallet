class PaymentRequest {
  PaymentRequest(this.address, this.amount, this.note);

  factory PaymentRequest.fromUri(Uri uri) {
    var address = "";
    var amount = "";
    var note = "";

    if (uri != null) {
      address = uri.path;
      amount = uri.queryParameters['tx_amount'] ?? uri.queryParameters['amount'] ?? "";
      note = uri.queryParameters['tx_description']
          ?? uri.queryParameters['message'] ?? "";
    }

    return PaymentRequest(address, amount, note);
  }

  final String address;
  final String amount;
  final String note;
}