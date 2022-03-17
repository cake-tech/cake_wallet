class PaymentRequest {
  String address;
  String amount;

  static PaymentRequest fromUri(Uri uri) {
    final PaymentRequest pr = new PaymentRequest();

    pr.address = "";
    pr.amount = "";

    if (uri != null) {
      pr.address = uri.path;
      pr.amount = uri.queryParameters['tx_amount'] ?? uri.queryParameters['amount'];
    }

    return pr;
  }
}