import "dart:convert";
import "dart:io";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/changenow/changenow_api_schema.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_found_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/utils/distribution_info.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class ChangeNowExchangeProvider extends ExchangeProvider {
  ChangeNowExchangeProvider({required SettingsStore settingsStore, super.proxyWrapper})
    : _settingsStore = settingsStore,
      _lastUsedRateId = "";

  static final apiKey = isMoneroOnly
      ? secrets.changeNowMoneroApiKey
      : secrets.changeNowCakeWalletApiKey;
  static const apiAuthority = "api.changenow.io";
  static const createTradePath = "/v2/exchange";
  static const findTradeByIdPath = "/v2/exchange/by-id";
  static const estimatedAmountPath = "/v2/exchange/estimated-amount";
  static const rangePath = "/v2/exchange/range";
  static const apiHeaderKey = "x-changenow-api-key";

  final SettingsStore _settingsStore;
  String _lastUsedRateId;

  @override
  String get title => "ChangeNOW";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.changeNow;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    if (from.title == "USDC" && from.tag == "POLY") {
      throw Exception("Only Bridged USDC (USDC.e) is allowed in ChangeNow");
    }

    final headers = {apiHeaderKey: apiKey};
    final params = ChangeNowRangeRequest(
      fromCurrency: _normalizeCurrency(from),
      toCurrency: _normalizeCurrency(to),
      fromNetwork: _networkFor(from),
      toNetwork: _networkFor(to),
      flow: isFixedRateMode ? ChangeNowFlow.fixedRate : ChangeNowFlow.standard,
    );
    final uri = Uri.https(apiAuthority, rangePath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri, headers: headers);

    if (response.statusCode == 400) {
      throw Exception(
        ChangeNowErrorResponse.fromJson(json.decode(response.body) as Map<String, dynamic>),
      );
    }

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseData = ChangeNowRangeResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
    if (responseData.maxAmount == 0) {
      return ExchangeLimits();
    }
    return ExchangeLimits(
      min: Money.tryParse(responseData.minAmount, from),
      max: Money.tryParse(responseData.maxAmount, from),
    );
  }

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required bool isFixedRate,
    required CryptoCurrency to,
  }) async {
    if (from.isZero) {
      throw Exception("cannot fetch rate with zero amount");
    }

    final headers = {apiHeaderKey: apiKey};

    final params = ChangeNowEstimatedAmountRequest(
      fromCurrency: _normalizeCurrency(from.currency as CryptoCurrency),
      toCurrency: _normalizeCurrency(to),
      fromAmount: isFixedRate ? null : from.toString(),
      toAmount:  isFixedRate ? from.toString() : null,
      fromNetwork: _networkFor(from.currency as CryptoCurrency),
      toNetwork: _networkFor(to),
      flow: isFixedRate ? ChangeNowFlow.fixedRate : ChangeNowFlow.standard,
      type: ChangeNowExchangeType.direct,
    );

    final uri = Uri.https(apiAuthority, estimatedAmountPath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri, headers: headers);
    if(response.statusCode < 200 || response.statusCode > 299) {
      throw Exception("status code: ${response.statusCode}\n${response.body}");
    }

    final responseData = ChangeNowEstimatedAmountResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
    if (responseData.fromAmount <= 0 || responseData.toAmount <= 0) {
      throw Exception("api returned bad amounts");
    }

    if (responseData.rateId?.isNotEmpty ?? false) {
      _lastUsedRateId = responseData.rateId!;
    }

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        Money.safeParse(responseData.fromAmount, from.currency),
        Money.safeParse(responseData.toAmount, to),
      ),
      limits: await fetchLimits(
        from: from.currency as CryptoCurrency,
        to: to,
        isFixedRateMode: isFixedRate,
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final distributionPath = await DistributionInfo.instance.getDistributionPath();
    final formattedAppVersion = int.tryParse(_settingsStore.appVersion.replaceAll(".", "")) ?? 0;
    final payload = ChangeNowCreateExchangePayload(
      app: isMoneroOnly ? "monerocom" : "cakewallet",
      device: Platform.operatingSystem,
      distribution: distributionPath,
      version: formattedAppVersion,
    );
    final headers = {apiHeaderKey: apiKey, "Content-Type": "application/json"};

    if (request.isFixedRate) {
      // since we schedule to calculate the rate every 5 seconds we need to ensure that
      // we have the latest rate id with the given inputs before creating the trade
      await fetchRate(
        from: request.depositAmount,
        to: request.payoutCurrency,
        isFixedRate: request.isFixedRate,
      );
    }
    final params = ChangeNowCreateExchangeRequest(
      fromCurrency: _normalizeCurrency(request.depositCurrency),
      toCurrency: _normalizeCurrency(request.payoutCurrency),
      fromNetwork: _networkFor(request.depositCurrency),
      toNetwork: _networkFor(request.payoutCurrency),
      fromAmount: request.depositAmount.toString(),
      toAmount: request.payoutAmount.toString(),
      address: request.payoutAddress,
      refundAddress: request.refundAddress,
      flow: request.isFixedRate ? ChangeNowFlow.fixedRate : ChangeNowFlow.standard,
      type: ChangeNowExchangeType.direct,
      payload: payload,
      rateId: _lastUsedRateId,
    );

    final uri = Uri.https(apiAuthority, createTradePath);
    final response = await proxyWrapper.post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(params.toJson()),
    );

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(ChangeNowErrorResponse.fromJson(responseJSON).message);
    }

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = ChangeNowCreateExchangeResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );

    return Trade(
      id: responseJSON.id,
      provider: description,
      fundingAddress: responseJSON.payinAddress,
      refundAddress: request.refundAddress,
      extraId: responseJSON.payinExtraId,
      createdAt: DateTime.now(),
      state: TradeState.created,
      toAddressExtraId: request.toAddressExtraId,
      depositAmount: request.depositAmount,
      payoutAmount: request.payoutAmount,
      payoutAddress: "",
    );
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final headers = {apiHeaderKey: apiKey};
    final params = ChangeNowByIdRequest(id: trade.id);
    final uri = Uri.https(apiAuthority, findTradeByIdPath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri, headers: headers);

    if (response.statusCode == 404) {
      throw TradeNotFoundException(trade.id, provider: description);
    }

    if (response.statusCode == 400) {
      final responseJSON = ChangeNowErrorResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
      throw TradeNotFoundException(trade.id, provider: description, description: responseJSON.message);
    }

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = ChangeNowTransactionResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );

    return trade.copyWith(
        state: responseJSON.status,
        createdAt: responseJSON.createdAt,
        expiredAt: responseJSON.validUntil,
        extraId: responseJSON.payinExtraId,
        outputTransaction: responseJSON.payoutHash,
        depositAmount: Money.safeParse(responseJSON.amountFrom, trade.depositCurrency),
        payoutAmount: Money.safeParse(responseJSON.amountTo, trade.payoutCurrency)
    );
  }

  String _networkFor(CryptoCurrency currency) =>
      currency.tag != null ? _normalizeTag(currency.tag!) : _normalizeTitleToNetwork(currency.title);

  String _normalizeTitleToNetwork(String title) => switch (title.toUpperCase()) {
    "XNO" => "nano",
    _ => title.toLowerCase(),
  };

  String _normalizeCurrency(CryptoCurrency currency) =>
      currency == CryptoCurrency.maticpoly ? "matic" : currency.title;

  String _normalizeTag(String tag) {
    switch (tag) {
      case "POLY":
      case "POL":
        return "matic";
      case "LN":
        return "lightning";
      case "AVAXC":
        return "cchain";
      case "ARB":
        return "arbitrum";
      default:
        return tag.toLowerCase();
    }
  }
}
