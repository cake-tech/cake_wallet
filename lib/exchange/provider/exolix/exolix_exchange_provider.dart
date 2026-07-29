import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/core/lightning_invoice_service.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/exolix/exolix_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_found_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class ExolixExchangeProvider extends ExchangeProvider {
  ExolixExchangeProvider({super.proxyWrapper});

  static final apiKey = isMoneroOnly ? secrets.exolixMoneroApiKey : secrets.exolixCakeWalletApiKey;
  static const apiBaseUrl = "exolix.com";
  static const transactionsPath = "/api/v2/transactions";
  static const ratePath = "/api/v2/rate";

  @override
  String get title => "Exolix";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.exolix;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final params = ExolixRateRequest(
      coinFrom: _normalizeCurrency(isFixedRateMode ? to : from),
      coinTo: _normalizeCurrency(isFixedRateMode ? from : to),
      networkFrom: _networkFor(isFixedRateMode ? to : from),
      amount: "1",
      networkTo: _networkFor(isFixedRateMode ? from : to),
      rateType: isFixedRateMode ? .fixed : .float,
      apiToken: apiKey,
    );

    final uri = Uri.https(apiBaseUrl, ratePath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri);

    if (response.statusCode == 200) {
      final responseData = ExolixRateResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
      return ExchangeLimits(
        min: Money.parse(responseData.minAmount, isFixedRateMode ? from : to),
        max: Money.parse(responseData.maxAmount, isFixedRateMode ? from : to),
      );
    } else if (response.statusCode == 422) {
      // HACK: exolix provides limits only if we ourselves supply an amount higher than minAmount.
      // i found no better workaround
      final errorResponse = json.decode(response.body) as Map<String, dynamic>;

      if (errorResponse.containsKey("minAmount")) {
        final paramsWithMin = ExolixRateRequest(
          coinFrom: params.coinFrom,
          coinTo: params.coinTo,
          networkFrom: params.networkFrom,
          networkTo: params.networkTo,
          rateType: params.rateType,
          amount: errorResponse["minAmount"].toString(),
          apiToken: apiKey,
        );

        final uri = Uri.https(apiBaseUrl, ratePath, paramsWithMin.toJson());
        final response = await proxyWrapper.get(clearnetUri: uri);

        if (response.statusCode == 200) {
          final responseData = ExolixRateResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
          return ExchangeLimits(
            min: Money.parse(responseData.minAmount, isFixedRateMode ? from : to),
            max: Money.parse(responseData.maxAmount, isFixedRateMode ? from : to),
          );
        }
      }
      throw Exception('Error 422: ${errorResponse['message'] ?? 'Unknown error'}');
    } else {
      throw Exception("Unexpected HTTP status: ${response.statusCode}");
    }
  }

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required bool isFixedRate,
    required CryptoCurrency to,
  }) async {
    final params = ExolixRateRequest(
      coinFrom: _normalizeCurrency(_overrideFromCryptoCurrency(from.currency as CryptoCurrency)),
      coinTo: _normalizeCurrency(to),
      networkFrom: _networkFor(from.currency as CryptoCurrency),
      networkTo: _networkFor(to),
      rateType: isFixedRate ? ExolixRateType.fixed : ExolixRateType.float,
      amount: from.toString(),
      apiToken: apiKey,
    );

    final uri = Uri.https(apiBaseUrl, ratePath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri);

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message = responseJSON["message"] as String?;

      throw Exception(message);
    }

    final responseData = ExolixRateResponse.fromJson(responseJSON);

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        Money.parse(responseData.fromAmount, from.currency),
        Money.parse(responseData.toAmount, to),
      ),
      limits: ExchangeLimits(
        min: Money.parse(responseData.minAmount, from.currency),
        max: Money.parse(responseData.maxAmount, from.currency),
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final headers = {"Content-Type": "application/json"};

    final body = ExolixCreateTransactionRequest(
      coinFrom: _normalizeCurrency(_overrideFromCryptoCurrency(request.depositAmount.currency)),
      coinTo: _normalizeCurrency(
        _overrideToCryptoCurrency(request.payoutAmount.currency, request.payoutAddress.address),
      ),
      networkFrom: _networkFor(request.depositAmount.currency),
      networkTo: _networkFor(request.depositAmount.currency),
      withdrawalAddress: await _normalizeAddress(request.payoutAddress.address),
      withdrawalAmount: request.isFixedRate ? request.payoutAmount.cryptoAmount.toString() : null,
      amount: request.isFixedRate ? null : request.depositAmount.cryptoAmount.toString(),
      rateType: request.isFixedRate ? ExolixRateType.fixed : ExolixRateType.float,
      apiToken: apiKey,
    );

    final uri = Uri.https(apiBaseUrl, transactionsPath);
    final response = await proxyWrapper.post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final errors = responseJSON["error"] as Map<String, String>;
      final errorMessage = errors.values.join(", ");

      throw Exception(errorMessage);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final responseData = ExolixTransactionResponse.fromJson(responseJSON);

    return Trade(
      id: responseData.id,
      provider: description,
      extraId: responseData.depositExtraId,
      createdAt: DateTime.now(),
      state: TradeState.created,
      toAddressExtraId: request.toAddressExtraId,
      depositAmount: Money.parse(responseData.amount, request.depositAmount.currency),
      payoutAmount: Money.parse(responseData.amountTo, request.payoutAmount.currency),
      fundingAddress: responseData.depositAddress,
      payoutAddress: responseData.withdrawalAddress,
      refundAddress: responseData.refundAddress ?? "",
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final findTradeByIdPath = "$transactionsPath/$id";
    final uri = Uri.https(apiBaseUrl, findTradeByIdPath);
    final response = await proxyWrapper.get(clearnetUri: uri);

    if (response.statusCode == 404) {
      throw TradeNotFoundException(id, provider: description);
    }

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final errors = responseJSON["errors"] as Map<String, String>;
      final errorMessage = errors.values.join(", ");

      throw TradeNotFoundException(id, provider: description, description: errorMessage);
    }

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final responseData = ExolixTransactionResponse.fromJson(responseJSON);

    // Parsing 'from' currency
    final coinFrom = responseData.coinFrom.coinCode;
    final coinFromNetwork = responseData.coinFrom.network;
    final _normalizedFromNetwork = _normalizeNetworkType(coinFromNetwork);
    final fromTag = coinFrom.toUpperCase() == _normalizedFromNetwork.toUpperCase()
        ? null
        : coinFromNetwork;
    final from = CryptoCurrency.safeParseCurrencyFromString(coinFrom, tag: fromTag);

    // Parsing 'to' currency
    final coinTo = responseData.coinTo.coinCode;
    final coinToNetwork = responseData.coinTo.network;
    final _normalizedToNetwork = _normalizeNetworkType(coinToNetwork);
    final toTag = coinTo.toUpperCase() == _normalizedToNetwork.toUpperCase() ? null : coinToNetwork;
    final to = CryptoCurrency.safeParseCurrencyFromString(coinTo, tag: toTag);

    return Trade(
      id: id,
      provider: description,
      state: responseData.status,
      extraId: responseData.depositExtraId,
      outputTransaction: responseData.hashOut.hash,
      payoutAddress: responseData.withdrawalAddress,
      depositAmount: Money.parse(responseData.amount, from!),
      payoutAmount: Money.parse(responseData.amountTo, to!),
      fundingAddress: responseData.depositAddress,
      refundAddress: responseData.refundAddress ?? "",
    );
  }

  String _networkFor(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.arb:
        return "ARBITRUM";
      case CryptoCurrency.btcln:
        return "LIGHTNING";
      default:
        return currency.tag != null ? _normalizeTag(currency.tag!) : currency.title;
    }
  }

  String _normalizeNetworkType(String network) => switch (network.toUpperCase()) {
    "ARBITRUM" => "ARB",
    _ => network,
  };

  CryptoCurrency _overrideFromCryptoCurrency(CryptoCurrency currency) {
    if (currency == CryptoCurrency.zec) {
      return CryptoCurrency.zaddr; // Sending is always shielded zcash
    }
    return currency;
  }

  CryptoCurrency _overrideToCryptoCurrency(CryptoCurrency currency, String address) {
    if (RegExp(r"u1[a-zA-Z0-9]{100,300}").hasMatch(address) && currency == CryptoCurrency.zec) {
      return CryptoCurrency.zaddr; // If the user pastes a unified address use shielded zcash
    }
    return currency;
  }

  String _normalizeCurrency(CryptoCurrency currency) => switch (currency) {
    CryptoCurrency.nano => "XNO",
    CryptoCurrency.bttc => "BTT",
    CryptoCurrency.zec => "ZEC",
    CryptoCurrency.zaddr => "ZEC-SHIELDED",
    _ => currency.title,
  };

  String _normalizeTag(String tag) {
    switch (tag) {
      case "POLY":
        return "Polygon";
      case "ARB":
        return "Arbitrum";
      default:
        return tag;
    }
  }

  Future<String> _normalizeAddress(String address) async {
    if (address.startsWith("bitcoincash:")) {
      return address.replaceFirst("bitcoincash:", "");
    }

    // Lightning addresses
    if (address.contains("@")) {
      return await getBolt11FromLightingAddress(address) ?? address;
    }

    return address;
  }
}
