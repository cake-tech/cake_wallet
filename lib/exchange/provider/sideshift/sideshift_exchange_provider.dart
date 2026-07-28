import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/sideshift/sideshift_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_created_exception.dart";
import "package:cake_wallet/exchange/trade_not_found_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

class SideShiftExchangeProvider extends ExchangeProvider {
  SideShiftExchangeProvider();

  static const affiliateId = secrets.sideShiftAffiliateId;
  static const apiBaseUrl = "https://sideshift.ai/api";
  static const rangePath = "/v2/pair";
  static const orderPath = "/v2/shifts";
  static const quotePath = "/v2/quotes";
  static const permissionPath = "/v2/permissions";

  @override
  String get title => "SideShift";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.sideShift;

  @override
  Future<bool> checkIsAvailable() async {
    const url = apiBaseUrl + permissionPath;
    final uri = Uri.parse(url);
    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode == 500) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON["error"]["message"] as String;

      throw Exception(error);
    }

    if (response.statusCode != 200) {
      return false;
    }

    final responseJSON = SideShiftPermissions.fromJson(json.decode(response.body) as Map<String, dynamic>);
    return responseJSON.createShift;
  }

  @override
  Future<ExchangeLimits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final fromCurrency = isFixedRateMode ? to : from;
    final toCurrency = isFixedRateMode ? from : to;

    final fromNetwork = _networkFor(fromCurrency);
    final toNetwork = _networkFor(toCurrency);

    final url =
        "$apiBaseUrl$rangePath/${fromCurrency.title.toLowerCase()}-$fromNetwork/${toCurrency.title.toLowerCase()}-$toNetwork";

    final uri = Uri.parse(url);
    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode == 500) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON["error"]["message"] as String;

      throw Exception("$error");
    }

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = SideShiftPair.fromJson(json.decode(response.body) as Map<String, dynamic>);

    // FIXME: i have no idea why this was needed.
    // limits are always for the deposit currency - doesn't matter if you use fixed rate or not.
    // this api doesn't even check fixed rate.
    // nonetheless this was added, perhaps to work around ui or api bugs.
    // it'll be unit tested anyway
    
    // if (isFixedRateMode) {
    //   final currentRate = double.parse(responseJSON['rate'] as String);
    //   return Limits(
    //     min: min != null ? (min * currentRate) : null,
    //     max: max != null ? (max * currentRate) : null,
    //   );
    // }

    return ExchangeLimits(
      min: Money.tryParse(responseJSON.min, fromCurrency),
          max: Money.tryParse(responseJSON.max, fromCurrency)
    );
  }

  @override
  Future<ProviderRate> fetchRate(
      {required Money from, required bool isFixedRate, required CryptoCurrency to}) async {
    final fromCurrency = from.currency.symbol.toLowerCase();
    final toCurrency = to.title.toLowerCase();
    final depositNetwork = _networkFor(from.currency as CryptoCurrency);
    final settleNetwork = _networkFor(to);

    final url =
        "$apiBaseUrl$rangePath/$fromCurrency-$depositNetwork/$toCurrency-$settleNetwork?amount=${from
        .amount.toString()}";

    final uri = Uri.parse(url);
    final response = await ProxyWrapper().get(clearnetUri: uri);


    if (response.statusCode == 500) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON["error"]["message"] as String;

      throw Exception("SideShift Internal Server Error: $error");
    }

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = SideShiftPair.fromJson(json.decode(response.body) as Map<String, dynamic>);

    return ProviderRate(provider: description,
        rate: ExchangeRate(base: from.currency, quote: Money.parse(responseJSON.rate, to)),
        limits: ExchangeLimits(
          min: Money.tryParse(responseJSON.min, from.currency),
          max: Money.tryParse(responseJSON.max, from.currency),
        ));


  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
  }) async {
    String url = "";

    final body;

    if(request.isFixedRate) {
      final quoteId = await _createQuote(request);
      url = "$apiBaseUrl$orderPath/fixed";
      body = SideShiftCreateFixedShiftRequest(settleAddress: request.payoutAddress.address,
        affiliateId: affiliateId,
        quoteId: quoteId,
        refundAddress: request.refundAddress,
        settleMemo: request.toAddressExtraId,
      );
    } else {
      url = "$apiBaseUrl$orderPath/variable";
      body = SideShiftCreateVariableShiftRequest(settleAddress: request.payoutAddress.address,
      affiliateId: affiliateId,
      settleMemo: request.toAddressExtraId,
      refundAddress: request.refundAddress,
      depositCoin: _normalizeCurrency(request.depositAmount.currency),
          settleCoin: _normalizeCurrency(request.payoutAmount.currency),
          depositNetwork: _networkFor(request.depositAmount.currency),
          settleNetwork: _networkFor(request.payoutAmount.currency),);
    }
    final headers = {"Content-Type": "application/json"};

    final uri = Uri.parse(url);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(body.toJson()),
    );

    if (response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON["error"]["message"] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseData = SideShiftShift.fromJson(json.decode(response.body) as Map<String, dynamic>);

    return Trade(
      id: responseData.id,
      provider: description,
      refundAddress: responseData.settleAddress,
      state: TradeState.created,
      createdAt: DateTime.now(),
      payoutAddress: responseData.settleAddress,
      payoutAmount: Money.parse(responseData.settleAmount, request.payoutAmount.currency),
      depositAmount: Money.parse(responseData.depositAmount, request.depositAmount.currency),
      fundingAddress: responseData.depositAddress,
      toAddressExtraId: request.toAddressExtraId,
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final url = "$apiBaseUrl$orderPath/$id";
    final uri = Uri.parse(url);
    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode == 404) {
      throw TradeNotFoundException(id, provider: description);
    }

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON["error"]["message"] as String;

      throw TradeNotFoundException(id, provider: description, description: error);
    }

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseData = SideShiftShift.fromJson(json.decode(response.body) as Map<String, dynamic>);
    // final fromCurrency = responseJSON['depositCoin'] as String;
    // final fromNetwork = responseJSON['depositNetwork'] as String?;
    // final toCurrency = responseJSON['settleCoin'] as String;
    // final toNetwork = responseJSON['settleNetwork'] as String?;
    // final inputAddress = responseJSON['depositAddress'] as String;
    // final expectedSendAmount = responseJSON['depositAmount'] as String?;
    // final status = responseJSON['status'] as String?;
    // final settleAddress = responseJSON['settleAddress'] as String;
    // final isVariable = (responseJSON['type'] as String) == 'variable';
    // final expiredAtRaw = responseJSON['expiresAt'] as String;
    // final expiredAt = isVariable ? null : DateTime.tryParse(expiredAtRaw)?.toLocal();
    // final depositMemo = responseJSON['depositMemo'] as String?;

    final fromParsed = CryptoCurrency.safeParseCurrencyFromString(
      responseData.depositCoin,
      tag: responseData.depositNetwork,
    );
    final toParsed = CryptoCurrency.safeParseCurrencyFromString(
      responseData.settleCoin,
      tag: responseData.settleNetwork,
    );
    return Trade(
        id: id,
        provider: description,
        state: responseData.status ?? TradeState.created,
        depositAmount: Money.parse(responseData.depositAmount, fromParsed!),
        payoutAmount: Money.parse(responseData.settleAmount, toParsed!),
        refundAddress: responseData.refundAddress ?? "",
        payoutAddress: responseData.settleAddress,
        fundingAddress: responseData.depositAddress
    );
  }

  Future<String> _createQuote(TradeRequest request) async {
    const url = apiBaseUrl + quotePath;
    final headers = {"Content-Type": "application/json"};
    final body = SideShiftQuoteRequest(
        depositCoin: _normalizeCurrency(request.depositAmount.currency),
        settleCoin: _normalizeCurrency(request.payoutAmount.currency),
        affiliateId: affiliateId,
        settleAmount: request.payoutAmount.cryptoAmount.toString(),
        settleNetwork: _networkFor(request.payoutAmount.currency),
        depositNetwork: _networkFor(request.depositAmount.currency)
    );
    final uri = Uri.parse(url);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(body.toJson()),
    );

    if (response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON["error"]["message"] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = SideShiftQuote.fromJson(json.decode(response.body) as Map<String, dynamic>);

    return responseJSON.id;
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.usdcEPoly:
        return "usdc";
      default:
        return currency.title.toLowerCase();
    }
  }

  String _networkFor(CryptoCurrency currency) =>
      currency.tag != null ? _normalizeTag(currency.tag!) : "mainnet";

  String _normalizeTag(String tag) {
    switch (tag) {
      case "ETH":
        return "ethereum";
      case "TRX":
        return "tron";
      case "LN":
        return "lightning";
      case "POL":
        return "polygon";
      case "ARB":
        return "arbitrum";
      case "ZEC":
        return "zcash";
      case "AVAXC":
        return "avax";
      default:
        return tag.toLowerCase();
    }
  }

}
