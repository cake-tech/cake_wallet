import "dart:convert";

import "dart:math";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/flashnet/flashnet_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_found_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class FlashnetExchangeProvider extends ExchangeProvider
    implements TransactionRegistrationExchangeProvider {

  static const baseUrl = "orchestration.flashnet.xyz";
  static const limitsPath = "/v1/orchestration/limits";
  static const estimatePath = "/v1/orchestration/estimate";
  static const quotePath = "/v1/orchestration/quote";
  static const submitPath = "/v1/orchestration/submit";
  static const statusPath = "/v1/orchestration/status";

  /// flashnet prefixes ids by kind, and a trade holds a quote id until /submit trades it for an
  /// order id
  static const quoteIdPrefix = "q_";
  static const apiKey = secrets.flashnetClientKey;
  static const slippageBps = 50;
  static const affiliateId = "cake_wallet";

  static const headers = {
    "Authorization": "Bearer ${apiKey}",
    "Content-Type": "application/json",
  };

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.flashnet;

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;


  @override
  Future<ExchangeLimits> fetchLimits({required CryptoCurrency from, required CryptoCurrency to, required bool isFixedRateMode}) async {
    final req = FlashnetLimitsRequest(
      sourceAsset: _normalizeCurrency(from),
      destinationAsset: _normalizeCurrency(to),
      sourceChain: _chainFor(from),
      destinationChain: _chainFor(to)
    );

    final resp = await proxyWrapper.get(headers: headers, clearnetUri: Uri.https(baseUrl, limitsPath, req.toJson()));
    if(resp.statusCode < 200 || resp.statusCode > 299) {
      throw Exception("status code: ${resp.statusCode}");
    }
    final respData = FlashnetLimitsResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);



    final routeLimits = respData.routes
        .map((item) => isFixedRateMode ? item.limits.exactOut : item.limits.exactIn)
        .where((item) => item.supported);

    if(routeLimits.isEmpty) {
      throw Exception("no routes");
    }

    final limitsCurrency = isFixedRateMode ? to : from;


    final Money? minAmount;
    final Money? maxAmount;

    final minAmounts = routeLimits
        .map((item) => item.requestAmount!.minAmountSmallest);
    if (minAmounts.any((item) => item == null)) {
      minAmount = null;
    } else {
      minAmount = minAmounts
          .map((item) => Money.safeParse(item, limitsCurrency, isBaseUnit: true))
          .min;
    }


    final maxAmounts = routeLimits
        .map((item) => item.requestAmount!.maxAmountSmallest);
    if (maxAmounts.any((item) => item == null)) {
      maxAmount = null;
    } else {
      maxAmount = maxAmounts
          .map((item) => Money.safeParse(item, limitsCurrency, isBaseUnit: true))
          .max;
    }

    return ExchangeLimits(min: minAmount, max: maxAmount);
  }

  @override
  Future<ProviderRate> fetchRate({required Money from, required CryptoCurrency to, required bool isFixedRate}) async {
    final req = FlashnetEstimateRequest(sourceChain: _chainFor(from.currency as CryptoCurrency),
        sourceAsset: _normalizeCurrency(from.currency as CryptoCurrency),
        destinationChain: _chainFor(to),
        destinationAsset: _normalizeCurrency(to),
        amount: from.toStringWithPrecision(useBaseUnit: true),
        amountMode: isFixedRate ? .exactOut : .exactIn,
        deliveryMode: isFixedRate ? .fixed : .variable,
        slippageBps: slippageBps,
      affiliateId: affiliateId
    );

    final resp = await proxyWrapper.get(headers: headers, clearnetUri: Uri.https(baseUrl, estimatePath, req.toJson()));
    if(resp.statusCode < 200 || resp.statusCode > 299) {
      throw Exception("status code: ${resp.statusCode}");
    }
    final respData = FlashnetEstimateResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);


    return ProviderRate(provider: description,
        rate: ExchangeRate.fromAmounts(
            from, Money.parse(respData.estimatedOut, to, isBaseUnit: true)),
        limits: await fetchLimits(
            from: from.currency as CryptoCurrency, to: to, isFixedRateMode: isFixedRate));
  }


  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final req = FlashnetQuoteRequest(
      sourceChain: _chainFor(request.depositCurrency),
      sourceAsset: _normalizeCurrency(request.depositCurrency),
      destinationChain: _chainFor(request.payoutCurrency),
      destinationAsset: _normalizeCurrency(request.payoutCurrency),
      amount:
      request.isFixedRate ?
      request.payoutAmount.toStringWithPrecision(useBaseUnit: true)
          : request.depositAmount.toStringWithPrecision(useBaseUnit: true),
      amountMode: request.isFixedRate ? .exactOut : .exactIn,
      deliveryMode: request.isFixedRate ? .fixed : .variable,
      recipientAddress: request.payoutAddress,
      refundAddress: request.refundAddress,
      affiliateId: affiliateId,
      slippageBps: slippageBps,

      refundChain: _chainFor(request.depositCurrency),
    );

    final resp = await proxyWrapper.post(
        headers: {...headers, "X-Idempotency-Key": _idempotencyKey},
        clearnetUri: Uri.https(baseUrl, quotePath),
        body: jsonEncode(req.toJson()));

    if(resp.statusCode < 200 || resp.statusCode > 299) {
      throw Exception("status code: ${resp.statusCode}\n${resp.body}");
    }

    final respData = FlashnetQuoteResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);

    return Trade(
      id: respData.quoteId,
      provider: description,
      state: TradeState.created,
      createdAt: DateTime.now(),
      expiredAt: respData.expiresAt,
      // exact_out prices the input as requiredAmountIn, exact_in quotes as amountIn
      depositAmount: Money.parse(
        respData.requiredAmountIn ?? respData.amountIn,
        request.depositCurrency,
        isBaseUnit: true,
      ),
      payoutAmount: Money.parse(
        respData.estimatedOut,
        request.payoutCurrency,
        isBaseUnit: true,
      ),
      fundingAddress: respData.depositAddress,
      payoutAddress: request.payoutAddress,
      refundAddress: request.refundAddress,
      extraId: respData.depositMemo,
      toAddressExtraId: request.toAddressExtraId,
      // only returned to client keys (fnp_), and status reads are refused without it. it is
      // bound to this quote, so it has nowhere to live but on the trade
      password: respData.readToken,
    );
  }

  @override
  Future<Trade> registerTransaction(Trade trade, String txHash) async {
    final req = switch (_chainFor(trade.depositCurrency)) {
      FlashnetChain.bitcoin => FlashnetSubmitRequest(quoteId: trade.id, bitcoinTxid: txHash),
      FlashnetChain.spark => FlashnetSubmitRequest(quoteId: trade.id, sparkTxHash: txHash),
      FlashnetChain.lightning => FlashnetSubmitRequest(quoteId: trade.id), // not a mistake, ln requires no txid
      _ => FlashnetSubmitRequest(quoteId: trade.id, txHash: txHash),
    };

    final resp = await proxyWrapper.post(
      headers: {
        ...headers,
        "X-Idempotency-Key": "${trade.id}:$txHash",
      },
      clearnetUri: Uri.https(baseUrl, submitPath),
      body: jsonEncode(req.toJson()),
    );

    if (resp.statusCode < 200 || resp.statusCode > 299) {
      throw Exception("status code: ${resp.statusCode}\n${resp.body}");
    }

    final respData =
        FlashnetSubmitResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);

    return trade.copyWith(
      id: respData.orderId,
      state: respData.status,
      txId: txHash,
      password: respData.readToken ?? trade.password,
    );
  }


  @override
  Future<Trade> updateTrade(Trade trade) async {
    final req = FlashnetStatusRequest(id: trade.id, readToken: trade.password);

    final resp = await proxyWrapper.get(headers: headers,
        clearnetUri: Uri.https(baseUrl, statusPath, req.toJson()));

    if (resp.statusCode == 404) {
      throw TradeNotFoundException(trade.id, provider: description);
    }

    if (resp.statusCode == 403) {
      final error = FlashnetErrorResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);

      throw TradeNotFoundException(trade.id, provider: description,
          description: "${error.error.code}: ${error.error.message} "
              "(read token ${trade.password}, ${trade.password?.length ?? 0} chars)");
    }

    if (resp.statusCode < 200 || resp.statusCode > 299) {
      throw Exception("status code: ${resp.statusCode}\n${resp.body}");
    }

    final respData =
    FlashnetStatusResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    final order = respData.order;

    return trade.copyWith(
      state: order.status,
      isRefund: order.refundTxHash != null,
      txId: order.sourceTxHash,
      outputTransaction: order.destinationTxHash,
      fundingAddress: order.depositAddress,
      payoutAddress: order.destinationAddress,
      depositAmount: order.amountIn == null
          ? null
          : Money.parse(order.amountIn, trade.depositCurrency, isBaseUnit: true),
      payoutAmount: order.amountOut == null
          ? null
          : Money.parse(order.amountOut, trade.payoutCurrency, isBaseUnit: true),
    );
  }



  @override
  String get title => description.title;

  String get _idempotencyKey {
    final rnd = Random.secure();

    return List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, "0")).join();
  }

  String _normalizeCurrency(CryptoCurrency currency) => switch (currency.title.toUpperCase()) {
    "USDC.E" => "USDC.e",
    "USDE" => "USDe",
    "CBBTC" => "cbBTC",
    "TBTC" => "tBTC",
    final title => title,
  };

  FlashnetChain _chainFor(CryptoCurrency currency) => currency.tag != null
      ? _normalizeTag(currency.tag!)
      : _normalizeTitleToChain(currency.title);

  FlashnetChain _normalizeTag(String tag) => switch (tag.toUpperCase()) {
    "ETH" => FlashnetChain.ethereum,
    "BSC" => FlashnetChain.bsc,
    "POL" => FlashnetChain.polygon,
    "ARB" => FlashnetChain.arbitrum,
    "BASE" => FlashnetChain.base,
    "AVAXC" => FlashnetChain.avalanche,
    "SOL" => FlashnetChain.solana,
    "TRX" => FlashnetChain.tron,
    "LN" => FlashnetChain.lightning,
    "ZEC" => FlashnetChain.zcash,
    _ => throw Exception("unsupported chain"),
  };

  FlashnetChain _normalizeTitleToChain(String title) => switch (title.toUpperCase()) {
    "BTC" => FlashnetChain.bitcoin,
    "ETH" => FlashnetChain.ethereum,
    "LTC" => FlashnetChain.litecoin,
    "XMR" => FlashnetChain.monero,
    "ZEC" => FlashnetChain.zcash,
    "XRP" => FlashnetChain.xrp,
    "TON" => FlashnetChain.ton,
    "SOL" => FlashnetChain.solana,
    "TRX" => FlashnetChain.tron,
    _ => throw Exception("unsupported chain"),
  };

}
