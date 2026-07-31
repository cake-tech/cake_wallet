import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/stealthex/stealthex_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_created_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class StealthExExchangeProvider extends ExchangeProvider {
  StealthExExchangeProvider({super.proxyWrapper});

  static const apiKey = secrets.stealthExBearerToken;
  static final _additionalFeePercent = double.tryParse(secrets.stealthExAdditionalFeePercent);
  static const _baseUrl = "https://api.stealthex.io";
  static const _rangePath = "/v4/rates/range";
  static const _amountPath = "/v4/rates/estimated-amount";
  static const _exchangesPath = "/v4/exchanges";

  @override
  String get title => "StealthEX";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.stealthEx;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits({required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode}) async {
    final curFrom = isFixedRateMode ? to : from;
    final curTo = isFixedRateMode ? from : to;

    final headers = {"Authorization": apiKey, "Content-Type": "application/json"};
    final body = StealthExRangeRequest(route: StealthExRoute(from: curFrom, to: curTo),
        estimation: isFixedRateMode ? StealthExEstimation.reversed : StealthExEstimation.direct,
        rate: isFixedRateMode ? .fixed : .floating,
        additionalFeePercent: _additionalFeePercent);

    final response = await proxyWrapper.post(
      clearnetUri: Uri.parse(_baseUrl + _rangePath),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("StealthEx fetch limits failed: ${response.body}");
    }
    final responseData = StealthExRange.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
    return ExchangeLimits(
      min: Money.tryParse(responseData.minAmount, from),
      max: Money.tryParse(responseData.maxAmount, from),
    );
  }

  @override
  Future<ProviderRate> fetchRate(
      {required Money from, required bool isFixedRate, required CryptoCurrency to}) async {
    final response = await getEstimatedExchangeAmount(
      from: from.currency as CryptoCurrency,
      to: to,
      amount: from.toDouble(),
      isFixedRateMode: isFixedRate,
    );

    if (response.estimatedAmount <= 0.0) {
      throw Exception("negative amount");
    }

    return ProviderRate(provider: description,
        rate: ExchangeRate.fromAmounts(from, Money.parse(response.estimatedAmount, to)),
        limits: await fetchLimits(
            from: from.currency as CryptoCurrency, to: to, isFixedRateMode: isFixedRate));
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    String? rateId;
    DateTime? validUntil;

    if (request.isFixedRate) {
      final response = await getEstimatedExchangeAmount(
          from: request.depositCurrency,
          to: request.payoutCurrency,
          amount: request.depositAmount.cryptoAmount.toDouble(),
          isFixedRateMode: request.isFixedRate);
      rateId = response.rate?.id;
      validUntil = response.rate?.validUntil;
      if (rateId == null) {
        throw TradeNotCreatedException(description);
      }
    }

    final headers = {"Authorization": apiKey, "Content-Type": "application/json"};
    // final body = {
    //   'route': {
    //     'from': {
    //       'symbol': _getName(request.fromCurrency),
    //       'network': _getNetwork(request.fromCurrency)
    //     },
    //     'to': {'symbol': _getName(request.toCurrency), 'network': _getNetwork(request.toCurrency)}
    //   },
    //   'estimation': isFixedRateMode ? 'reversed' : 'direct',
    //   'rate': isFixedRateMode ? 'fixed' : 'floating',
    //   if (isFixedRateMode) 'rate_id': rateId,
    //   'amount':
    //       isFixedRateMode ? double.parse(request.toAmount) : double.parse(request.fromAmount),
    //   'address': _normalizeAddress(request.toAddress),
    //   if (request.toAddressExtraId.isNotEmpty) 'extra_id': request.toAddressExtraId,
    //   'refund_address': _normalizeAddress(request.refundAddress),
    //   'additional_fee_percent': _additionalFeePercent,
    // };
    final body = StealthExCreateExchangeRequest(
        route: StealthExRoute(from: request.depositCurrency, to: request.payoutCurrency),
        amount: request.isFixedRate ? request.payoutAmount.cryptoAmount.toDouble() : request
            .depositAmount.cryptoAmount.toDouble(),
        estimation: request.isFixedRate ? .reversed : .direct,
        rate: request.isFixedRate ? .fixed : .floating,
        address: _normalizeAddress(request.payoutAddress),
        refundAddress: _normalizeAddress(request.refundAddress),
        extraId: request.toAddressExtraId,
        additionalFeePercent: _additionalFeePercent
    );

    final response = await proxyWrapper.post(
      clearnetUri: Uri.parse(_baseUrl + _exchangesPath),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 201) {
      throw Exception("StealthEx create trade failed: ${response.body}");
    }
    final responseData = StealthExExchange.fromJson(
        json.decode(response.body) as Map<String, dynamic>);

    final createdAt = responseData.createdAt.toLocal();
    final expiredAt = validUntil != null
        ? validUntil.toLocal()
        : DateTime.now().add(const Duration(minutes: 5));

    CryptoCurrency fromCurrency;
    if (request.depositCurrency.tag != null &&
        request.depositCurrency.title.toLowerCase() == responseData.deposit.symbol) {
      fromCurrency = request.depositCurrency;
    } else {
      fromCurrency = CryptoCurrency.fromString(responseData.deposit.symbol);
    }

    CryptoCurrency toCurrency;
    if (request.payoutCurrency.tag != null &&
        request.payoutCurrency.title.toLowerCase() == responseData.withdrawal.symbol) {
      toCurrency = request.payoutCurrency;
    } else {
      toCurrency = CryptoCurrency.fromString(responseData.withdrawal.symbol);
    }


    return Trade(
      id: responseData.id,
      provider: description,
      fundingAddress: responseData.deposit.address,
      payoutAddress: responseData.withdrawal.address,
      refundAddress: responseData.refundAddress ?? "",
      state: responseData.status,
      createdAt: createdAt,
      expiredAt: expiredAt,
      extraId: responseData.deposit.extraId,
      toAddressExtraId: request.toAddressExtraId,
      depositAmount: Money.parse(responseData.deposit.amount, fromCurrency),
      payoutAmount: Money.parse(responseData.withdrawal.amount, toCurrency),
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final headers = {"Authorization": apiKey, "Content-Type": "application/json"};

    final uri = Uri.parse("$_baseUrl$_exchangesPath/$id");
    final response = await proxyWrapper.get(clearnetUri: uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception("StealthEx fetch trade failed: ${response.body}");
    }
    final responseData = StealthExExchange.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
    // Parsing 'from' currency with network tag
    final fromTag = responseData.deposit.network == "mainnet" ? null : responseData.deposit.network;
    final from = CryptoCurrency.safeParseCurrencyFromString(
        responseData.deposit.symbol, tag: fromTag);
    // Parsing 'to' currency with network tag
    final toTag = responseData.withdrawal.network == "mainnet" ? null : responseData.withdrawal
        .network;
    final to = CryptoCurrency.safeParseCurrencyFromString(
        responseData.withdrawal.symbol, tag: toTag);


    return Trade(
      id: responseData.id,
      provider: description,
      fundingAddress: responseData.deposit.address,
      payoutAddress: responseData.withdrawal.address,
      refundAddress: responseData.refundAddress ?? "",
      state: responseData.status,
      createdAt: responseData.createdAt,
      isRefund: responseData.status == .refunded,
      extraId: responseData.deposit.extraId,
      depositAmount: Money.parse(responseData.deposit.amount, from!),
      payoutAmount: Money.parse(responseData.withdrawal.amount, to!),
    );
  }

  Future<StealthExEstimate> getEstimatedExchangeAmount({required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode}) async {
    final headers = {"Authorization": apiKey, "Content-Type": "application/json"};

    final body = StealthExEstimateRequest(route: StealthExRoute(from: from, to: to),
        amount: amount,
        estimation: isFixedRateMode ? .reversed : .direct,
        rate: isFixedRateMode ? .fixed : .floating,
        additionalFeePercent: _additionalFeePercent);

    final response = await proxyWrapper.post(
      clearnetUri: Uri.parse(_baseUrl + _amountPath),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("stealthex estimated rate response: ${response.statusCode}");
    }
    return StealthExEstimate.fromJson(json.decode(response.body) as Map<String, dynamic>);
  }


  String _normalizeAddress(String address) =>
      address.startsWith("bitcoincash:") ? address.replaceFirst("bitcoincash:", "") : address;
}
