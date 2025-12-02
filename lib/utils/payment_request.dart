import 'package:cake_wallet/core/payment_uris.dart';
import 'package:cake_wallet/nano/nano.dart';

class PaymentRequest {
  PaymentRequest(this.address, this.amount, this.note, this.scheme, this.pjUri,
      {this.callbackUrl, this.callbackMessage, this.contractAddress});

  factory PaymentRequest.fromUri(Uri? uri) {
    var address = "";
    var amount = "";
    var note = "";
    var scheme = "";
    String? walletType;
    String? callbackUrl;
    String? callbackMessage;
    String? pjUri;
    String? contractAddress;

    if (uri != null) {
      if (uri.queryParameters['pj'] != null) {
        pjUri = uri.toString();
      }

      address = uri.queryParameters['address'] ?? uri.path;
      amount = uri.queryParameters['tx_amount'] ?? uri.queryParameters['amount'] ?? "";
      note = uri.queryParameters['tx_description'] ?? uri.queryParameters['message'] ?? "";
      scheme = uri.scheme;
      callbackUrl = uri.queryParameters['callback'];
      callbackMessage = uri.queryParameters['callbackMessage'];
      walletType = uri.queryParameters['type'];

      if (scheme == "ethereum") {
        final paymentUri = ERC681URI.fromUri(uri);

        address = paymentUri.address;
        amount = paymentUri.amount;
        contractAddress = paymentUri.contractAddress;
      }
    }

    if (scheme == "nano-gpt") {
      scheme = walletType ?? "nano";
    }

    if (nano != null) {
      if (amount.isNotEmpty) {
        if (!_isAlreadyUsableAmount(amount)) {
          if (address.contains("nano")) {
            amount = nanoUtil!.getRawAsUsableString(amount, nanoUtil!.rawPerNano);
          } else if (address.contains("ban")) {
            amount = nanoUtil!.getRawAsUsableString(amount, nanoUtil!.rawPerBanano);
          }
        }
      }
    }

    return PaymentRequest(
      address,
      amount,
      note,
      scheme,
      pjUri,
      callbackUrl: callbackUrl,
      callbackMessage: callbackMessage,
      contractAddress: contractAddress,
    );
  }

  final String address;
  final String amount;
  final String note;
  final String scheme;
  final String? pjUri;
  final String? callbackUrl;
  final String? callbackMessage;
  final String? contractAddress;

  /// Checks if the amount string is already in a usable format (e.g., "123.45") and doesn't need to be converted from raw format.
  ///
  /// This was causing an error for us when we scan Nano QRs with amounts in them, the amounts are already in usable format so when the parsing was done, it returns 0 wrongly.
  static bool _isAlreadyUsableAmount(String amount) {
    if (amount.isEmpty) return false;

    // Try to parse as double - if successful, it's already in usable format
    final parsed = double.tryParse(amount.replaceAll(',', '.'));
    if (parsed == null) return false;

    // Check if the amount contains a decimal point and is a reasonable number,
    // it's likely already in usable format rather than raw format
    // Raw amounts are typically very large integers without decimal points
    if (amount.contains('.') && parsed > 0 && parsed < 1000000000) return true;

    // If it's a small integer (less than 1 billion), it's likely already usable
    if (parsed == parsed.toInt() && parsed < 1000000000) return true;

    return false;
  }
}
