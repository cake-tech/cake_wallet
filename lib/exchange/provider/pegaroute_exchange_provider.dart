import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/limits.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_found_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/utils/exchange_provider_logger.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

class PegaRouteExchangeProvider extends ExchangeProvider {
  PegaRouteExchangeProvider();

  static const apiKey = secrets.pegaRouteApiKey;
  static const apiBaseUrl = "api.pegaroute.com";
  static const quotePath = "/quote";
  static const swapPath = "/swap";

  static final Map<String, String> _headers = {"X-API-Key": apiKey};

  @override
  String get title => "PegaRoute";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.pegaRoute;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits?> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final params = <String, String>{
      "fromChain": _chainFor(from),
      "fromToken": _tokenFor(from),
      "toChain": _chainFor(to),
      "toToken": _tokenFor(to),
      "amount": "1",
    };

    final uri = Uri.https(apiBaseUrl, quotePath, params);
    final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    // All routes rejected the amount as too low; the error message may carry the minimum
    if (response.statusCode == 400) {
      final error = responseJSON["error"] as Map<String, dynamic>?;
      final min = _extractAmount(error?["message"] as String? ?? "");
      return Limits(min: min ?? 0, max: null);
    }

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final routes = responseJSON["routes"] as List<dynamic>? ?? [];

    double? min;
    if (routes.isNotEmpty) {
      min = _toDouble((routes.first as Map<String, dynamic>)["minAmount"]);
    }

    if (min == null) {
      final warnings = responseJSON["warnings"] as List<dynamic>? ?? [];
      for (final warning in warnings) {
        final warningMap = warning as Map<String, dynamic>;
        if (warningMap["code"] == "AMOUNT_TOO_LOW") {
          min = _extractAmount(warningMap["message"] as String? ?? "");
          if (min != null) break;
        }
      }
    }

    return Limits(min: min ?? 0, max: null);
  }

  @override
  Future<double> fetchRate({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
  }) async {
    try {
      if (amount == 0) return 0.0;

      // PegaRoute is float-only: quotes always take the source amount
      final params = <String, String>{
        "fromChain": _chainFor(from),
        "fromToken": _tokenFor(from),
        "toChain": _chainFor(to),
        "toToken": _tokenFor(to),
        "amount": amount.toString(),
      };

      final uri = Uri.https(apiBaseUrl, quotePath, params);
      final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

      final responseJSON = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final error = responseJSON["error"] as Map<String, dynamic>?;
        final message = error?["userMessage"] as String? ?? error?["message"] as String?;

        ExchangeProviderLogger.logError(
          provider: description,
          function: "fetchRate",
          error: Exception(message ?? "Unknown error"),
          stackTrace: StackTrace.current,
          requestData: {
            "from": from.title,
            "to": to.title,
            "amount": amount,
            "isFixedRateMode": isFixedRateMode,
            "isReceiveAmount": isReceiveAmount,
            "params": params,
            "url": uri.toString(),
          },
        );

        throw Exception(message);
      }

      final routes = responseJSON["routes"] as List<dynamic>? ?? [];
      if (routes.isEmpty) return 0.0;

      final expectedOutput = double.tryParse(
            (routes.first as Map<String, dynamic>)["expectedOutput"]?.toString() ?? "",
          ) ??
          0.0;
      final rate = expectedOutput / amount;

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: "fetchRate",
        requestData: {
          "from": from.title,
          "to": to.title,
          "amount": amount,
          "isFixedRateMode": isFixedRateMode,
          "isReceiveAmount": isReceiveAmount,
          "params": params,
          "url": uri.toString(),
        },
        responseData: {
          "rate": rate,
          "statusCode": response.statusCode,
          "responseJSON": responseJSON,
        },
      );

      return rate;
    } catch (e, s) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: "fetchRate",
        error: e,
        stackTrace: s,
        requestData: {
          "from": from.title,
          "to": to.title,
          "amount": amount,
          "isFixedRateMode": isFixedRateMode,
          "isReceiveAmount": isReceiveAmount,
        },
      );
      printV(e.toString());
      printV(s.toString());
      return 0.0;
    }
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    final quoteParams = <String, String>{
      "fromChain": _chainFor(request.fromCurrency),
      "fromToken": _tokenFor(request.fromCurrency),
      "toChain": _chainFor(request.toCurrency),
      "toToken": _tokenFor(request.toCurrency),
      "amount": request.fromAmount,
    };

    final quoteUri = Uri.https(apiBaseUrl, quotePath, quoteParams);
    final quoteResponse = await ProxyWrapper().get(clearnetUri: quoteUri, headers: _headers);
    final quoteJSON = json.decode(quoteResponse.body) as Map<String, dynamic>;

    if (quoteResponse.statusCode != 200) {
      final error = quoteJSON["error"] as Map<String, dynamic>?;
      final errorMessage = error?["userMessage"] as String? ??
          error?["message"] as String? ??
          "Unexpected http status: ${quoteResponse.statusCode}";

      ExchangeProviderLogger.logError(
        provider: description,
        function: "createTrade",
        error: Exception(errorMessage),
        stackTrace: StackTrace.current,
        requestData: {
          "from": request.fromCurrency.title,
          "to": request.toCurrency.title,
          "fromAmount": request.fromAmount,
          "toAddress": request.toAddress,
          "refundAddress": request.refundAddress,
          "isFixedRateMode": isFixedRateMode,
          "isSendAll": isSendAll,
          "params": quoteParams,
          "url": quoteUri.toString(),
        },
      );

      throw Exception(errorMessage);
    }

    final routes = quoteJSON["routes"] as List<dynamic>? ?? [];
    if (routes.isEmpty) throw Exception("No routes available for this pair");

    final route = routes.first as Map<String, dynamic>;
    final quoteId = quoteJSON["quoteId"] as String?;

    final body = <String, dynamic>{
      "fromChain": _chainFor(request.fromCurrency),
      "fromToken": _tokenFor(request.fromCurrency),
      "toChain": _chainFor(request.toCurrency),
      "toToken": _tokenFor(request.toCurrency),
      "amount": request.fromAmount,
      "destinationAddress": request.toAddress,
      "senderAddress": request.refundAddress,
      if (quoteId != null) "quoteId": quoteId,
      if (route["provider"] != null) "routeProvider": route["provider"],
    };

    final uri = Uri.https(apiBaseUrl, swapPath);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: {..._headers, "Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode != 202 && response.statusCode != 200) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON["error"] as Map<String, dynamic>?;
      final errorMessage = error?["userMessage"] as String? ??
          error?["message"] as String? ??
          "Unexpected http status: ${response.statusCode}";

      ExchangeProviderLogger.logError(
        provider: description,
        function: "createTrade",
        error: Exception(errorMessage),
        stackTrace: StackTrace.current,
        requestData: {
          "from": request.fromCurrency.title,
          "to": request.toCurrency.title,
          "fromAmount": request.fromAmount,
          "toAddress": request.toAddress,
          "refundAddress": request.refundAddress,
          "isFixedRateMode": isFixedRateMode,
          "isSendAll": isSendAll,
          "body": body,
          "url": uri.toString(),
        },
      );

      throw Exception(errorMessage);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON["transactionId"] as String;
    // Current schema: execution (chain-family payload) + provider (reference/details);
    // txParams is the legacy shape kept as fallback during their rollout.
    final execution = responseJSON["execution"] as Map<String, dynamic>? ?? {};
    final providerInfo = responseJSON["provider"] as Map<String, dynamic>? ?? {};
    final txParams = responseJSON["txParams"] as Map<String, dynamic>? ?? {};
    final inputAddress = execution["to"] as String? ?? txParams["to"] as String?;
    final providerId =
        providerInfo["referenceId"] as String? ?? txParams["providerReferenceId"] as String?;
    final details = providerInfo["details"] as Map<String, dynamic>?;
    final instaswapSwapLite = (details?["instaswapSwapLite"] ?? txParams["instaswapSwapLite"])
        as Map<String, dynamic>?;
    final expiresAtRaw = instaswapSwapLite?["expiresAt"] as String?;
    final expiredAt = expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw)?.toLocal() : null;
    final receiveAmount = route["expectedOutput"]?.toString();

    ExchangeProviderLogger.logSuccess(
      provider: description,
      function: "createTrade",
      requestData: {
        "from": request.fromCurrency.title,
        "to": request.toCurrency.title,
        "fromAmount": request.fromAmount,
        "toAddress": request.toAddress,
        "refundAddress": request.refundAddress,
        "isFixedRateMode": isFixedRateMode,
        "isSendAll": isSendAll,
        "body": body,
        "url": uri.toString(),
      },
      responseData: {
        "id": id,
        "inputAddress": inputAddress,
        "providerId": providerId,
        "receiveAmount": receiveAmount,
        "statusCode": response.statusCode,
        "responseJSON": responseJSON,
      },
    );

    return Trade(
      id: id,
      from: request.fromCurrency,
      to: request.toCurrency,
      provider: description,
      inputAddress: inputAddress,
      refundAddress: request.refundAddress,
      createdAt: DateTime.now(),
      expiredAt: expiredAt,
      amount: request.fromAmount,
      receiveAmount: receiveAmount ?? request.toAmount,
      state: TradeState.created,
      payoutAddress: request.toAddress,
      providerId: providerId,
      isSendAll: isSendAll,
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final uri = Uri.https(apiBaseUrl, "$swapPath/$id");
    final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (response.statusCode == 404) throw TradeNotFoundException(id, provider: description);

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final internalStatus =
        responseJSON["internalStatus"] as String? ?? responseJSON["status"] as String? ?? "";
    final input = responseJSON["input"] as Map<String, dynamic>? ?? {};
    final output = responseJSON["output"] as Map<String, dynamic>? ?? {};

    final from = _parseCurrency(input["chain"] as String?, input["token"] as String?);
    final to = _parseCurrency(output["chain"] as String?, output["token"] as String?);

    return Trade(
      id: id,
      from: from,
      to: to,
      provider: description,
      inputAddress: input["address"] as String?,
      amount: input["amount"]?.toString() ?? "",
      state: _tradeState(internalStatus),
      outputTransaction: output["txHash"] as String?,
      receiveAmount: output["amount"]?.toString(),
      payoutAddress: output["address"] as String?,
    );
  }

  /// Registers the broadcasted deposit tx hash with PegaRoute
  /// (required to start provider-side monitoring). Never throws.
  static Future<bool> submitTxHash({required String id, required String txHash}) async {
    try {
      final uri = Uri.https(apiBaseUrl, "$swapPath/$id/txhash");
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: {..._headers, "Content-Type": "application/json"},
        body: json.encode({"txHash": txHash}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        printV("submitTxHash failed: ${response.statusCode} ${response.body}");
        ExchangeProviderLogger.logError(
          provider: ExchangeProviderDescription.pegaRoute,
          function: "submitTxHash",
          error: Exception("Unexpected http status: ${response.statusCode}"),
          stackTrace: StackTrace.current,
          requestData: {"id": id, "txHash": txHash},
        );
        return false;
      }

      return true;
    } catch (e, s) {
      printV("submitTxHash error: $e");
      ExchangeProviderLogger.logError(
        provider: ExchangeProviderDescription.pegaRoute,
        function: "submitTxHash",
        error: e,
        stackTrace: s,
        requestData: {"id": id, "txHash": txHash},
      );
      return false;
    }
  }

  // Cake currency tags that differ from PegaRoute chain ids (GET /chains)
  static const _chainAliases = <String, String>{
    "ARB": "ARBITRUM",
    "AVAXC": "AVAX",
    "POL": "POLYGON",
    "TRX": "TRON",
  };

  String _chainFor(CryptoCurrency currency) {
    final chain = (currency.tag ?? currency.title).toUpperCase();
    return _chainAliases[chain] ?? chain;
  }

  String _tokenFor(CryptoCurrency currency) {
    // ERC-20/SPL tokens are contract-qualified ('SYMBOL-<contract>');
    // unsupported ids simply fail server-side with UNSUPPORTED_PAIR
    if (currency is Erc20Token)
      return "${currency.title.toUpperCase()}-${currency.contractAddress}";
    if (currency is SPLToken) return "${currency.title.toUpperCase()}-${currency.mintAddress}";
    return currency.title.toUpperCase();
  }

  CryptoCurrency? _parseCurrency(String? chain, String? token) {
    if (token == null) return null;
    final symbol = token.split("-").first;
    final tag = chain != null && chain.toUpperCase() != symbol.toUpperCase() ? chain : null;
    return CryptoCurrency.safeParseCurrencyFromString(symbol, tag: tag);
  }

  TradeState _tradeState(String internalStatus) {
    switch (internalStatus) {
      case "pending":
        return TradeState.created;
      case "submitted":
        return TradeState.confirming;
      case "executing":
        return TradeState.exchanging;
      case "confirming":
        return TradeState.sending;
      case "completed":
        return TradeState.success;
      case "failed":
        return TradeState.failed;
      case "refunded":
        return TradeState.refunded;
      default:
        return TradeState.deserialize(raw: internalStatus);
    }
  }

  double? _extractAmount(String message) {
    final match = RegExp(r"\d+(?:\.\d+)?").firstMatch(message);
    return match != null ? double.tryParse(match.group(0)!) : null;
  }

  static double? _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
