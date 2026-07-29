import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/letsexchange/letsexchange_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class LetsExchangeExchangeProvider extends ExchangeProvider {
  LetsExchangeExchangeProvider({super.proxyWrapper});

  static const apiKey = secrets.letsExchangeBearerToken;
  static const _baseUrl = "api.letsexchange.io";
  static const _infoPath = "/api/v1/info";
  static const _infoRevertPath = "/api/v1/info-revert";
  static const _createTransactionPath = "/api/v1/transaction";
  static const _createTransactionRevertPath = "/api/v1/transaction-revert";
  static const _getTransactionPath = "/api/v1/transaction";

  static const _affiliateId = secrets.letsExchangeAffiliateId;

  @override
  String get title => "LetsExchange";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.letsExchange;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final params = LetsExchangeInfoRequest(
      float: !isFixedRateMode,
      from: from.symbol,
      to: to.title,
      networkFrom: _getNetworkType(from),
      networkTo: _getNetworkType(to),
      amount: "1",
      affiliateId: _affiliateId,
    );

    final responseData = await _getInfo(params, isFixedRateMode);

    return ExchangeLimits(
      min: Money.parse(responseData.minAmount, from),
      max: Money.parse(responseData.maxAmount, from),
    );
  }

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required bool isFixedRate,
    required CryptoCurrency to,
  }) async {
    final params = LetsExchangeInfoRequest(
      float: !isFixedRate,
      from: from.currency.symbol,
      to: to.title,
      networkFrom: _getNetworkType(from.currency as CryptoCurrency),
      networkTo: _getNetworkType(to),
      amount: from.toString(),
      affiliateId: _affiliateId,
    );

    final responseData = await _getInfo(params, isFixedRate);

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(from, Money.parse(responseData.amount, to)),
      limits: ExchangeLimits(
        min: Money.parse(responseData.minAmount, from.currency),
        max: Money.parse(responseData.maxAmount, from.currency),
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final networkFrom = _getNetworkType(request.depositAmount.currency);
    final networkTo = _getNetworkType(request.payoutAmount.currency);

    final params = LetsExchangeInfoRequest(
      from: request.depositAmount.currency.title,
      to: request.payoutAmount.currency.title,
      networkFrom: networkFrom,
      networkTo: networkTo,
      amount: request.depositAmount.toString(),
      affiliateId: _affiliateId,
      float: !request.isFixedRate,
    );

    final responseInfoJSON = await _getInfo(params, request.isFixedRate);
    final rateId = responseInfoJSON.rateId!;

    final withdrawalAddress = _normalizeBchAddress(request.payoutAddress.address);
    final returnAddress = _normalizeBchAddress(request.refundAddress);

    final tradeParams = LetsExchangeCreateTransactionRequest(
      coinFrom: request.depositAmount.currency.title,
      coinTo: request.payoutAmount.currency.title,
      depositAmount: request.isFixedRate ? null : request.depositAmount.cryptoAmount.toString(),
      withdrawalAmount: request.isFixedRate ? request.payoutAmount.cryptoAmount.toString() : null,
      withdrawal: withdrawalAddress,
      withdrawalExtraId: request.toAddressExtraId,
      returnAddress: returnAddress,
      rateId: rateId,
      networkFrom: networkFrom,
      networkTo: networkTo,
      affiliateId: _affiliateId,
      float: !request.isFixedRate,
    );

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": apiKey,
    };

    final uri = Uri.https(
      _baseUrl,
      request.isFixedRate ? _createTransactionRevertPath : _createTransactionPath,
    );
    final response = await proxyWrapper.post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(tradeParams.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("LetsExchange create trade failed: ${response.body}");
    }
    final responseData = LetsExchangeTransactionResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );

    // the null checks are because api spec shows EVERY FIELD as nullable
    return Trade(
      id: responseData.transactionId!,
      provider: description,
      payoutAddress: responseData.withdrawal!,
      fundingAddress: responseData.deposit!,
      refundAddress: request.refundAddress,
      payoutAmount: Money.parse(responseData.withdrawalAmount, request.payoutAmount.currency),
      depositAmount: Money.parse(responseData.depositAmount, request.depositAmount.currency),
      state: responseData.status!,
      createdAt: responseData.createdAt,
      expiredAt: responseData.expiredAt,
      extraId: responseData.depositExtraId,
      toAddressExtraId: request.toAddressExtraId,
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": apiKey,
    };

    final url = Uri.https(_baseUrl, "$_getTransactionPath/$id");
    final response = await proxyWrapper.get(clearnetUri: url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception("LetsExchange fetch trade failed: ${response.body}");
    }
    final responseData = LetsExchangeTransactionResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
    //
    // // Parsing 'from' currency
    // final fromCurrency = responseJSON["coin_from"] as String;
    // final fromNetwork = responseJSON["coin_from_network"] as String?;
    // final normalizedFromNetwork = _normalizeNetworkType(fromNetwork ?? "");
    // final fromTag = fromCurrency == normalizedFromNetwork ? null : normalizedFromNetwork;
    // final from = CryptoCurrency.safeParseCurrencyFromString(fromCurrency, tag: fromTag);
    //
    // // Parsing 'to' currency
    // final toCurrency = responseJSON["coin_to"] as String;
    // final toNetwork = responseJSON["coin_to_network"] as String?;
    // final normalizedToNetwork = _normalizeNetworkType(toNetwork ?? "");
    // final toTag = toCurrency == normalizedToNetwork ? null : normalizedToNetwork;
    // final to = CryptoCurrency.safeParseCurrencyFromString(toCurrency, tag: toTag);
    //
    // final payoutAddress = responseJSON["withdrawal"] as String;
    // final depositAddress = responseJSON["deposit"] as String;
    // final refundAddress = responseJSON["return"] as String;
    // final depositAmount = responseJSON["deposit_amount"] as String;
    // final receiveAmount = responseJSON["withdrawal_amount"] as String;
    // final status = responseJSON["status"] as String;
    //
    // final extraId = responseJSON["deposit_extra_id"] as String?;

    return Trade(
      id: id,
      provider: description,
      payoutAddress: responseData.withdrawal!,
      refundAddress: responseData.returnAddress!,
      state: responseData.status!,
      isRefund: responseData.status == TradeState.refund,
      extraId: responseData.depositExtraId,
      depositAmount: Money.parse(
        responseData.deposit,
        CryptoCurrency.safeParseCurrencyFromString(
          responseData.coinFrom,
          tag: _normalizeNetworkType(responseData.coinFromNetwork!),
        )!,
      ),
      payoutAmount: Money.parse(
        responseData.withdrawal,
        CryptoCurrency.safeParseCurrencyFromString(
          responseData.coinTo,
          tag: _normalizeNetworkType(responseData.coinToNetwork!),
        )!,
      ),
      fundingAddress: responseData.deposit!,
    );
  }

  Future<LetsExchangeInfoResponse> _getInfo(
    LetsExchangeInfoRequest params,
    bool isFixedRateMode,
  ) async {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": apiKey,
    };

    final uri = Uri.https(_baseUrl, isFixedRateMode ? _infoRevertPath : _infoPath);
    final response = await proxyWrapper.post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(params.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("LetsExchange fetch info failed: ${response.body}");
    }
    return LetsExchangeInfoResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);
  }

  String? _getNetworkType(CryptoCurrency currency) {
    if (currency.tag != null && currency.tag!.isNotEmpty) {
      switch (currency.tag!) {
        case "TRX":
          return "TRC20";
        case "ETH":
          return "ERC20";
        case "BSC":
          return "BEP20";
        case "ARB":
          return "ARBITRUM";
        default:
          return currency.tag!;
      }
    }

    return _normalizeTitleToNetwork(currency.title);
  }

  String _normalizeNetworkType(String network) => switch (network.toUpperCase()) {
    "ERC20" => "ETH",
    "TRC20" => "TRX",
    "BEP20" => "BSC",
    "ARBITRUM" => "ARB",
    _ => network,
  };

  String _normalizeTitleToNetwork(String title) => switch (title.toUpperCase()) {
    "ARB" => "ARBITRUM",
    _ => title,
  };

  String _normalizeBchAddress(String address) =>
      address.startsWith("bitcoincash:") ? address.substring(12) : address;
}
