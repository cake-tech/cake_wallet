import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/format_fixed.dart';

class PaymentRequest {
  PaymentRequest(this.address, this.amount, this.note, this.scheme, this.pjUri,
      {this.callbackUrl, this.callbackMessage});

  factory PaymentRequest.fromUri(Uri? uri) {
    var address = "";
    var amount = "";
    var note = "";
    var scheme = "";
    String? walletType;
    String? callbackUrl;
    String? callbackMessage;
    String? pjUri;

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
      }
    }

    if (scheme == "nano-gpt") {
      scheme = walletType ?? "nano";
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
      pjUri,
      callbackUrl: callbackUrl,
      callbackMessage: callbackMessage,
    );
  }

  final String address;
  final String amount;
  final String note;
  final String scheme;
  final String? pjUri;
  final String? callbackUrl;
  final String? callbackMessage;
}

class ERC681URI extends PaymentURI {
  final int chainId;
  final String? contractAddress;

  ERC681URI({
    required this.chainId,
    required super.address,
    required super.amount,
    required this.contractAddress,
  });

  factory ERC681URI.fromUri(Uri uri) {
    final (isContract, targetAddress) = _getTargetAddress(uri.path);
    final chainId = _getChainID(uri.path);

    final address = isContract ? uri.queryParameters["address"] ?? '' : targetAddress;
    final amount = isContract
        ? uri.queryParameters["uint256"]
        : uri.queryParameters["value"];

    var formatedAmount = "";

    if (amount != null) {
      formatedAmount = formatFixed(BigInt.parse(amount), 18);
    } else {
      formatedAmount = uri.queryParameters["amount"] ?? "";
    }

    return ERC681URI(
      chainId: chainId,
      address: address,
      amount: formatedAmount,
      contractAddress: isContract ? targetAddress : null,
    );
  }

  static int _getChainID(String path) {
    return int.parse(RegExp(
      r'@\d*',
    ).firstMatch(path)?.group(0)?.replaceAll("@", "") ??
        "1");
  }

  static (bool, String) _getTargetAddress(String path) {
    final targetAddress = RegExp(r'^(0x)?[0-9a-f]{40}', caseSensitive: false)
        .firstMatch(path)!
        .group(0)!;
    return (path.contains("/"), targetAddress);
  }
}
