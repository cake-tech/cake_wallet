import "package:cake_wallet/nano/nano.dart";
import "package:cw_core/amount/amount_sanitizer.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/format_fixed.dart";
import "package:cw_core/lnurl.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/utils/print_verbose.dart";

class PaymentRequest {
  PaymentRequest(
    this.address,
    this.amount,
    this.note,
    this.scheme,
    this.pjUri, {
    this.callbackUrl,
    this.callbackMessage,
    this.contractAddress,
    this.chainId,
    this.rawTokenAmount,
  });

  factory PaymentRequest.fromString(String input) {
    try {
      return PaymentRequest.fromBolt11(input);
    } catch (_) {
      try {
        return PaymentRequest.fromUri(Uri.parse(input));
      } catch (_) {
        return PaymentRequest(input, "", "", "", null);
      }
    }
  }

  factory PaymentRequest.fromBolt11(String invoice) {
    final amount = getBolt11Amount(invoice) ?? Money.zero(CryptoCurrency.btcln);
    return PaymentRequest(invoice, amount.toString(), "", "lightning", null);
  }

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
    int? chainId;
    String? rawTokenAmount;

    if (uri != null) {
      if (uri.queryParameters["pj"] != null) {
        pjUri = uri.toString();
      }

      address = uri.queryParameters["address"] ?? uri.path;
      try {
        final lnAmount = getBolt11Amount(uri.path) ?? Money.zero(CryptoCurrency.btcln);

        if (lnAmount != 0) {
          amount = lnAmount.toString();
        }
      } catch (_) {}
      if (amount.isEmpty) {
        amount = uri.queryParameters["tx_amount"] ?? uri.queryParameters["amount"] ?? "";
      }
      note = uri.queryParameters["tx_description"] ?? uri.queryParameters["message"] ?? "";
      scheme = uri.scheme;
      callbackUrl = uri.queryParameters["callback"];
      callbackMessage = uri.queryParameters["callbackMessage"];
      walletType = uri.queryParameters["type"];

      if (scheme == "ethereum") {
        final paymentUri = ERC681URI.fromUri(uri);
        final hasExplicitChainId = uri.path.contains("@");

        address = paymentUri.address;
        amount = paymentUri.amount;
        contractAddress = paymentUri.contractAddress;
        chainId = hasExplicitChainId ? paymentUri.chainId : null;
        rawTokenAmount = paymentUri.rawTokenAmount;
      } else if (scheme == "tron") {
        final token = uri.queryParameters["token"];
        if (token != null && token.isNotEmpty) {
          contractAddress = token;
        }
      } else if (scheme == "solana") {
        final splToken = uri.queryParameters["spl-token"];
        if (splToken != null && splToken.isNotEmpty) {
          contractAddress = splToken;
        }
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
      chainId: chainId,
      rawTokenAmount: rawTokenAmount,
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
  final int? chainId;
  final String? rawTokenAmount;

  String? resolveTokenAmount(CryptoCurrency token) {
    if (amount.isNotEmpty) {
      return amount;
    }

    if (rawTokenAmount == null || rawTokenAmount!.isEmpty) {
      return null;
    }

    final raw = BigInt.tryParse(rawTokenAmount!);
    if (raw == null) {
      return null;
    }

    // 1e9 whole tokens is beyond any real payment, so a larger result means the QR
    // came from an old app version that encoded with 18 decimals regardless of token.
    if (token.decimals != 18 && raw > BigInt.from(10).pow(token.decimals + 9)) {
      printV("resolveTokenAmount: reading $rawTokenAmount with legacy 18 decimals");
      return formatFixed(raw, 18);
    }

    return formatFixed(raw, token.decimals);
  }

  /// Checks if the amount string is already in a usable format (e.g., "123.45") and doesn't need to be converted from raw format.
  ///
  /// This was causing an error for us when we scan Nano QRs with amounts in them, the amounts are already in usable format so when the parsing was done, it returns 0 wrongly.
  static bool _isAlreadyUsableAmount(String amount) {
    if (amount.isEmpty) {
      return false;
    }

    final parsed = double.tryParse(amount.sanitized());
    if (parsed == null) {
      return false;
    }
    if (amount.contains(".") && parsed > 0 && parsed < 1000000000) {
      return true;
    }

    // If it's a small integer (less than 1 billion), it's likely already usable
    if (parsed == parsed.toInt() && parsed < 1000000000) {
      return true;
    }

    return false;
  }
}
