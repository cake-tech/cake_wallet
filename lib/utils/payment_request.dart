import 'package:cake_wallet/nano/nano.dart';

class PaymentRequest {
  PaymentRequest(this.address, this.amount, this.note, this.scheme, {this.callback});

  factory PaymentRequest.fromUri(Uri? uri) {
    var address = "";
    var amount = "";
    var note = "";
    var scheme = "";
    String? callback;

    if (uri != null) {
      address = uri.queryParameters['address'] ?? uri.path;
      amount = uri.queryParameters['tx_amount'] ?? uri.queryParameters['amount'] ?? "";
      note = uri.queryParameters['tx_description'] ?? uri.queryParameters['message'] ?? "";
      scheme = uri.scheme;
      callback = uri.queryParameters['callback'];
    }

    if (scheme == "nano-gpt") {
      // treat as nano so filling out the address works:
      scheme = "nano";
    }

    if (nano != null) {
      if (amount.isNotEmpty) {
        if (address.contains("nano")) {
          amount = nanoUtil!.getRawAsUsableString(amount, nanoUtil!.rawPerNano);
        } else if (address.contains("ban")) {
          amount = nanoUtil!.getRawAsUsableString(amount, nanoUtil!.rawPerBanano);
        }
      }
    }

    return PaymentRequest(
      address,
      amount,
      note,
      scheme,
      callback: callback,
    );
  }

  final String address;
  final String amount;
  final String note;
  final String scheme;
  final String? callback;
}
