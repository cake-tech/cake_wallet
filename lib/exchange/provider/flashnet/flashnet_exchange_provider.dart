import "dart:math";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_exceptions.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/flashnet/flashnet_api_schema.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_created_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class FlashnetExchangeProvider extends LimitsCacheExchangeProvider
    implements TransactionRegistrationExchangeProvider {
  FlashnetExchangeProvider({super.proxyWrapper});

  static const _apiAuthority = "orchestration.flashnet.xyz";

  static const _submitPropagationRetries = 3;
  static const _submitRetryDelay = Duration(seconds: 1);

  static const apiKey = secrets.flashnetClientKey;
  static const slippageBps = 50;
  static const affiliateId = "cake_wallet";

  late final _api = ProviderApi(
    proxyWrapper,
    authority: _apiAuthority,
    headers: const {"Authorization": "Bearer $apiKey"},
    errorMessage: (json) => switch (json["error"]) {
      {"code": final Object code, "message": final Object message} => "$code: $message",
      _ => null,
    },
  );

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.flashnet;

  @override
  bool get supportsFixedRate => true;


  @override
  Future<ExchangeLimits> fetchLimits({required CryptoCurrency from, required CryptoCurrency to, required bool isFixedRateMode}) async {
    final respData = await _api.send(
      FlashnetLimitsRequest(
        sourceAsset: _normalizeCurrency(from),
        destinationAsset: _normalizeCurrency(to),
        sourceChain: _chainFor(from),
        destinationChain: _chainFor(to),
      ),
    );

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
  Future<ProviderRate> fetchRate(RateRequest request) async {
    final respData = await _api.send(
      FlashnetEstimateRequest(
        sourceChain: _chainFor(request.depositCurrency),
        sourceAsset: _normalizeCurrency(request.depositCurrency),
        destinationChain: _chainFor(request.payoutCurrency),
        destinationAsset: _normalizeCurrency(request.payoutCurrency),
        amount: request.amount.toStringWithPrecision(useBaseUnit: true),
        amountMode: request is FixedRateRequest ? .exactOut : .exactIn,
        slippageBps: slippageBps,
        affiliateId: affiliateId,
      ),
    );

    final rate = switch (request) {
      FloatingRateRequest(:final depositAmount) => ExchangeRate.fromAmounts(
        depositAmount,
        Money.parse(respData.estimatedOut, request.payoutCurrency, isBaseUnit: true),
      ),
      FixedRateRequest(:final payoutAmount) => ExchangeRate.fromAmounts(
        Money.parse(
          respData.requiredAmountIn ?? (throw Exception("no requiredAmountIn on exact_out estimate")),
          request.depositCurrency,
          isBaseUnit: true,
        ),
        payoutAmount,
      ),
    };

    final limits = await getLimits(
      from: request.depositCurrency,
      to: request.payoutCurrency,
      isFixedRateMode: request is FixedRateRequest,
    );

    return ProviderRate(
      provider: description,
      rate: rate,
      // exact_out limits come in the payout asset, but RatesLoaded compares every provider's
      // limits against each other in the deposit asset
      limits: switch (request) {
        FloatingRateRequest() => limits,
        FixedRateRequest() => ExchangeLimits(
          min: limits.min == null ? null : rate.convert(limits.min!),
          max: limits.max == null ? null : rate.convert(limits.max!),
        ),
      },
    );
  }


  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final respData = await _api.send(
      FlashnetQuoteRequest(
        sourceChain: _chainFor(request.depositCurrency),
        sourceAsset: _normalizeCurrency(request.depositCurrency),
        destinationChain: _chainFor(request.payoutCurrency),
        destinationAsset: _normalizeCurrency(request.payoutCurrency),
        amount:
        request.isFixedRate ?
        request.payoutAmount.toStringWithPrecision(useBaseUnit: true)
            : request.depositAmount.toStringWithPrecision(useBaseUnit: true),
        amountMode: request.isFixedRate ? .exactOut : .exactIn,
        recipientAddress: request.payoutAddress,
        refundAddress: request.refundAddress,
        affiliateId: affiliateId,
        slippageBps: slippageBps,

        refundChain: _chainFor(request.depositCurrency),
      ),
      headers: {"X-Idempotency-Key": _idempotencyKey},
      mapError: (e) => TradeNotCreatedException(description, description: e.message),
    );

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

    final respData = await _getSubmitResponse(req, "${trade.id}:$txHash");


    return trade.copyWith(
      id: respData.orderId,
      state: respData.status,
      txId: txHash,
      password: respData.readToken,
    );
  }

  Future<FlashnetSubmitResponse> _getSubmitResponse(FlashnetSubmitRequest req,
      String idempotencyKey) async {
    int attempt = 1;


    // flashnet requires the tx to have been propagated before /submit.
    // if it's not propagated the api will return tx_not_found
    // this means we have to keep trying /submit until it's propagated, usually just a few seconds
    while (true) {
      await Future<void>.delayed(_submitRetryDelay * attempt);
      try {
        return await _api.send(req, headers: {"X-Idempotency-Key": idempotencyKey});
      } on ProviderHttpException catch (e) {
        if (e.json case {"error": {"code": "tx_not_found"}}) {
          attempt++;
          if (attempt > _submitPropagationRetries) {
            throw Exception("max submit retries exceeded");
          }
          continue;
        }
        rethrow;
      }
    }
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final respData = await _api.send(
      FlashnetStatusRequest(id: trade.id, readToken: trade.password),
      mapError: (e) => switch (e.statusCode) {
        404 => TradeNotFoundException(trade.id, provider: description),
        403 => TradeNotFoundException(trade.id, provider: description,
            description: "${e.message} "
                "(read token ${trade.password}, ${trade.password?.length ?? 0} chars)"),
        _ => null,
      },
    );
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
          : Money.parse(order.amountIn!, trade.depositCurrency, isBaseUnit: true),
      payoutAmount: order.amountOut == null
          ? null
          : Money.parse(order.amountOut!, trade.payoutCurrency, isBaseUnit: true),
    );
  }


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
