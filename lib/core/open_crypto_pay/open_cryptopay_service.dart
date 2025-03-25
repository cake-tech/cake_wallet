import 'dart:convert';
import 'dart:developer';

import 'package:cake_wallet/core/open_crypto_pay/exceptions.dart';
import 'package:cake_wallet/core/open_crypto_pay/lnurl.dart';
import 'package:cake_wallet/core/open_crypto_pay/models.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:http/http.dart';

class OpenCryptoPayService {
  static bool isOpenCryptoPayQR(String value) =>
      value.toLowerCase().contains("lightning=lnurl") ||
      value.toLowerCase().startsWith("lnurl");

  final Client _httpClient = Client();

  Future<String> commitOpenCryptoPayRequest(
    String txHex, {
    required OpenCryptoPayRequest request,
    required CryptoCurrency asset,
  }) async {
    final uri = Uri.parse(request.callbackUrl.replaceAll("/cb/", "/tx/"));

    final queryParams = Map.of(uri.queryParameters);

    queryParams['quote'] = request.quote;
    queryParams['asset'] = asset.title;
    queryParams['method'] = asset.fullName ?? 'Monero';
    queryParams['hex'] = "$txHex";

    final response =
        await _httpClient.get(Uri.https(uri.authority, uri.path, queryParams));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map;

      if (body.keys.contains("txId")) return body["txId"] as String;
      throw OpenCryptoPayException(body.toString());
    }
    throw OpenCryptoPayException(
        "Unexpected status code ${response.statusCode} ${response.body}");
  }

  Future<void> cancelOpenCryptoPayRequest(OpenCryptoPayRequest request) async {
    final uri = Uri.parse(request.callbackUrl.replaceAll("/cb/", "/cancel/"));

    await _httpClient.delete(uri);
  }

  Future<OpenCryptoPayRequest> getOpenCryptoPayInvoice(String lnUrl) async {
    if (lnUrl.toLowerCase().startsWith("http")) {
      final uri = Uri.parse(lnUrl);
      final params = uri.queryParameters;
      if (!params.containsKey("lightning")) {
        throw OpenCryptoPayNotSupportedException(uri.authority);
      }

      lnUrl = params["lightning"] as String;
    }
    final url = decodeLNURL(lnUrl);

    printV("Resolved URL: $url");

    final params = await _getOpenCryptoPayParams(url);

    return OpenCryptoPayRequest(
        address: "",
        amount: BigInt.zero,
        receiverName: params.$1.displayName ?? "Unknown",
        expiry: params.$1.expiration.difference(DateTime.now()).inSeconds,
        callbackUrl: params.$1.callbackUrl,
        quote: params.$1.id);
  }

  Future<(_OpenCryptoPayQuote, Map<String, num>)> _getOpenCryptoPayParams(
      Uri uri) async {
    final response = await _httpClient.get(uri);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map;

      for (final key in ['callback', 'transferAmounts', 'quote']) {
        if (!responseBody.keys.contains(key)) {
          throw OpenCryptoPayNotSupportedException(uri.authority);
        }
      }

      final methods = <String, List<_OpenCryptoPayQuoteAsset>>{};
      for (final transferAmountRaw in responseBody['transferAmounts'] as List) {
        final transferAmount = transferAmountRaw as Map;
        final method = transferAmount['method'] as String;
        methods[method] = [];
        for (final assetJson in transferAmount['assets'] as List) {
          final asset = _OpenCryptoPayQuoteAsset.fromJson(
              assetJson as Map<String, dynamic>);
          methods[method]?.add(asset);
        }
      }

      log(responseBody.toString());

      final quote = _OpenCryptoPayQuote.fromJson(
          responseBody['callback'] as String,
          responseBody['displayName'] as String?,
          responseBody['quote'] as Map<String, dynamic>);

      return (quote, <String, num>{});
    } else {
      throw OpenCryptoPayException(
          'Failed to get Open CryptoPay Request. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<Uri> getOpenCryptoPayAddress(
      OpenCryptoPayRequest request, CryptoCurrency asset) async {
    final uri = Uri.parse(request.callbackUrl);
    final queryParams = Map.of(uri.queryParameters);

    queryParams['quote'] = request.quote;
    queryParams['asset'] = asset.title;
    queryParams['method'] = asset.fullName ?? 'Monero';

    final response =
        await _httpClient.get(Uri.https(uri.authority, uri.path, queryParams));

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map;

      printV(responseBody);
      for (final key in ['expiryDate', 'uri']) {
        if (!responseBody.keys.contains(key)) {
          throw OpenCryptoPayNotSupportedException(uri.authority);
        }
      }

      return Uri.parse(responseBody['uri'] as String);
    } else {
      throw OpenCryptoPayException(
          'Failed to create Open CryptoPay Request. Status: ${response.statusCode} ${response.body}');
    }
  }
}

class _OpenCryptoPayQuote {
  final String callbackUrl;
  final String? displayName;
  final String id;
  final DateTime expiration;

  _OpenCryptoPayQuote(
      this.callbackUrl, this.displayName, this.id, this.expiration);

  _OpenCryptoPayQuote.fromJson(
      this.callbackUrl, this.displayName, Map<String, dynamic> json)
      : id = json['id'] as String,
        expiration = DateTime.parse(json['expiration'] as String);
}

class _OpenCryptoPayQuoteAsset {
  final String symbol;
  final String amount;

  const _OpenCryptoPayQuoteAsset(this.symbol, this.amount);

  _OpenCryptoPayQuoteAsset.fromJson(Map<String, dynamic> json)
      : symbol = json['asset'] as String,
        amount = (json['amount'] as double).toString();
}
