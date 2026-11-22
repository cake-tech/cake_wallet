import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/whynot/whynot_api_schema.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class WhyNotExchangeProvider extends ExchangeProvider {
  WhyNotExchangeProvider({super.proxyWrapper});

  static const apiKey = secrets.whyNotBearerToken;
  static const _baseUrl = "api.y-not.io";
  static const _infoPath = "/api/v1/info";
  static const _infoRevertPath = "/api/v1/info-revert";
  static const _createTransactionPath = "/api/v1/transaction";
  static const _createTransactionRevertPath = "/api/v1/transaction-revert";
  static const _getTransactionPath = "/api/v1/transaction";

  static const _affiliateId = secrets.whyNotAffiliateId;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.whyNot;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    if (_isExcluded(from) || _isExcluded(to)) {
      throw Exception("WhyNot's USDD on Ethereum and Tron is not the official contract");
    }

    final params = WhyNotInfoRequest(
      float: !isFixedRateMode,
      from: from.symbol,
      to: to.title,
      networkFrom: _getNetworkType(from),
      networkTo: _getNetworkType(to),
      amount: 1,
      affiliateId: _affiliateId,
    );

    final responseData = await _getInfo(params, isFixedRateMode);

    return ExchangeLimits(
      min: Money.safeParse(responseData.depositMinAmount, from),
      max: Money.safeParse(responseData.depositMaxAmount, from),
    );
  }

  @override
  Future<ProviderRate> fetchRate(RateRequest request) async {
    if (_isExcluded(request.depositCurrency) || _isExcluded(request.payoutCurrency)) {
      throw Exception("WhyNot's USDD on Ethereum and Tron is not the official contract");
    }

    final params = WhyNotInfoRequest(
      float: request is FloatingRateRequest,
      from: request.depositCurrency.symbol,
      to: request.payoutCurrency.title,
      networkFrom: _getNetworkType(request.depositCurrency),
      networkTo: _getNetworkType(request.payoutCurrency),
      amount: double.parse(request.amount.toString()),
      affiliateId: _affiliateId,
    );

    final responseData = await _getInfo(params, request is FixedRateRequest);

    return ProviderRate(
      provider: description,
      rate: switch (request) {
        FloatingRateRequest(:final depositAmount) => ExchangeRate.fromAmounts(
          depositAmount,
          Money.safeParse(responseData.amount, request.payoutCurrency),
        ),
        FixedRateRequest(:final payoutAmount) => ExchangeRate.fromAmounts(
          Money.safeParse(responseData.amount, request.depositCurrency),
          payoutAmount,
        ),
      },
      limits: ExchangeLimits(
        min: Money.safeParse(responseData.depositMinAmount, request.depositCurrency),
        max: Money.safeParse(responseData.depositMaxAmount, request.depositCurrency),
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    if (_isExcluded(request.depositCurrency) || _isExcluded(request.payoutCurrency)) {
      throw Exception("WhyNot's USDD on Ethereum and Tron is not the official contract");
    }

    final networkFrom = _getNetworkType(request.depositCurrency);
    final networkTo = _getNetworkType(request.payoutCurrency);

    final params = WhyNotInfoRequest(
      from: request.depositCurrency.title,
      to: request.payoutCurrency.title,
      networkFrom: networkFrom,
      networkTo: networkTo,
      amount: double.parse(
        (request.isFixedRate ? request.payoutAmount : request.depositAmount).toString(),
      ),
      affiliateId: _affiliateId,
      float: !request.isFixedRate,
    );

    final responseInfoJSON = await _getInfo(params, request.isFixedRate);

    final withdrawalAddress = _normalizeBchAddress(request.payoutAddress);
    final returnAddress = _normalizeBchAddress(request.refundAddress);

    final tradeParams = WhyNotCreateTransactionRequest(
      coinFrom: request.depositCurrency.title,
      coinTo: request.payoutCurrency.title,
      depositAmount: request.isFixedRate ? null : request.depositAmount.toString(),
      withdrawalAmount: request.isFixedRate ? request.payoutAmount.toString() : null,
      withdrawal: withdrawalAddress,
      withdrawalExtraId: request.toAddressExtraId ?? "",
      returnAddress: returnAddress,
      rateId: responseInfoJSON.rateId,
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
      throw Exception("WhyNot create trade failed: ${response.body}");
    }
    final responseData = WhyNotTransactionResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );

    // the null checks are because api spec shows EVERY FIELD as nullable
    return Trade(
      id: responseData.transactionId!,
      provider: description,
      payoutAddress: responseData.withdrawal!,
      fundingAddress: responseData.deposit!,
      refundAddress: request.refundAddress,
      payoutAmount: Money.safeParse(responseData.withdrawalAmount, request.payoutAmount.currency),
      depositAmount: Money.safeParse(responseData.depositAmount, request.depositAmount.currency),
      state: responseData.status!,
      createdAt: DateTime.now(),
      expiredAt: responseData.expiredAt,
      extraId: responseData.depositExtraId,
      toAddressExtraId: request.toAddressExtraId,
    );
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": apiKey,
    };

    final url = Uri.https(_baseUrl, "$_getTransactionPath/${trade.id}");
    final response = await proxyWrapper.get(clearnetUri: url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception("WhyNot fetch trade failed: ${response.body}");
    }
    final responseData = WhyNotTransactionResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );

    return trade.copyWith(
      payoutAddress: responseData.withdrawal,
      refundAddress: responseData.returnAddress,
      state: responseData.status,
      isRefund: responseData.status == TradeState.refund,
      extraId: responseData.depositExtraId,
      depositAmount: Money.safeParse(
        responseData.depositAmount,
        trade.depositCurrency
      ),
      payoutAmount: Money.safeParse(
        responseData.withdrawalAmount,
        trade.payoutCurrency
      ),
      fundingAddress: responseData.deposit,
    );
  }

  Future<WhyNotInfoResponse> _getInfo(
    WhyNotInfoRequest params,
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
      throw Exception("WhyNot fetch info failed: ${response.body}");
    }
    return WhyNotInfoResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);
  }

  bool _isExcluded(CryptoCurrency currency) =>
      currency.title.toUpperCase() == "USDD" && ["TRX", "ETH"].contains(currency.tag);

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
        // WhyNot's USDT on OPTIMISM is the legacy 0x94b0 USDT, not USDT0
        case "OP" when currency.title.toUpperCase() == "USDC":
          return "OPTIMISM";
        default:
          return currency.tag!;
      }
    }

    return _normalizeTitleToNetwork(currency.title);
  }

  String _normalizeTitleToNetwork(String title) => switch (title.toUpperCase()) {
    "ARB" => "ARBITRUM",
    _ => title,
  };

  String _normalizeBchAddress(String address) =>
      address.startsWith("bitcoincash:") ? address.substring(12) : address;
}
