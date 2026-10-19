import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/exchange/exchange_exceptions.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swaptrade/swaptrade_api_schema.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_created_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class SwapTradeExchangeProvider extends ExchangeProvider {
  SwapTradeExchangeProvider({super.proxyWrapper});

  static final markup = double.tryParse(secrets.swapTradeExchangeMarkup) ?? 0;

  static const apiAuthority = "api.swaptrade.io";

  late final _api = ProviderApi(
    proxyWrapper,
    authority: apiAuthority,
    errorMessage: (json) => switch (json["errors"]) {
      [{"msg": final Object msg}, ...] => msg.toString(),
      _ => (json["msg"] ?? json["message"])?.toString(),
    },
  );

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.swapTrade;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final coins = await _fetchCoins();
    _networkFor(from, coins);
    _networkFor(to, coins);
    return _limitsFor(from, coins);
  }

  @override
  Future<ProviderRate> fetchRate(RateRequest request) async {
    if (request is! FloatingRateRequest) {
      throw Exception("fixed rate unsupported");
    }
    if (request.depositCurrency == CryptoCurrency.btcln ||
        request.payoutCurrency == CryptoCurrency.btcln) {
      throw Exception("lightning not supported");
    }

    final coins = await _fetchCoins();
    final responseBody = await _api.send(
      SwapTradeGetPriceRequest(
        coinSend: _normalizeCurrency(request.depositCurrency),
        coinSendNetwork: _networkFor(request.depositCurrency, coins),
        coinReceiveNetwork: _networkFor(request.payoutCurrency, coins),
        coinReceive: _normalizeCurrency(request.payoutCurrency),
        amountSend: request.depositAmount.toString(),
        markup: markup,
      ),
    );

    if (responseBody.success == false) {
      final error = responseBody.errors?.firstOrNull?.msg;
      throw Exception(error ?? "rejected the quote: ${responseBody.msg}");
    }

    final payout = responseBody.data?.price;

    if(payout == null) {
      throw Exception("payout is null: ${responseBody.msg}");
    }

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        request.depositAmount,
        Money.parse(payout.toStringAsFixed(request.payoutCurrency.decimals), request.payoutCurrency),
      ),
      limits: _limitsFor(request.depositCurrency, coins),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final coins = await _fetchCoins();
    final responseBody = await _api.send(
      SwapTradeCreateOrderRequest(
        coinSend: _normalizeCurrency(request.depositCurrency),
        coinSendNetwork: _networkFor(request.depositCurrency, coins),
        coinReceive: _normalizeCurrency(request.payoutCurrency),
        coinReceiveNetwork: _networkFor(request.payoutCurrency, coins),
        amountSend: request.depositAmount.toString(),
        recipient: request.payoutAddress,
        markup: markup,
        ref: "cake",
        refundAddress: request.refundAddress,
      ),
      mapError: (e) => switch (e.statusCode) {
        400 => TradeNotCreatedException(description, description: e.message),
        _ => null,
      },
    );

    if (responseBody.success == false) {
      final error = responseBody.errors?.firstOrNull?.msg ?? responseBody.msg ?? "";
      throw TradeNotCreatedException(description, description: error);
    }

    final responseData = responseBody.data;

    return Trade(
      id: responseData!.orderId,
      fundingAddress: responseData.serverAddress,
      provider: description,
      createdAt: DateTime.now(),
      state: TradeState.created,
      payoutAddress: request.payoutAddress,
      refundAddress: request.refundAddress,
      depositAmount: request.depositAmount,
      payoutAmount: Money.safeParse(responseData.amountReceive ?? 0, request.payoutCurrency),
    );
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final responseBody = await _api.send(
      SwapTradeOrderRequest(orderId: trade.id),
      mapError: (e) => switch (e.statusCode) {
        400 => TradeNotFoundException(trade.id, provider: description, description: e.message),
        _ => null,
      },
    );

    if (responseBody.success == false) {
      final error = responseBody.errors?.firstOrNull?.msg ?? responseBody.msg ?? "";
      throw TradeNotFoundException(trade.id, provider: description, description: error);
    }

    final responseData = responseBody.data!;

    return trade.copyWith(
      state: responseData.status,
      memo: responseData.memo,
      createdAt: responseData.createdAt,
      depositAmount: Money.safeParse(
        responseData.amountSend,
        trade.depositCurrency,
      ),
      payoutAmount: Money.safeParse(
        responseData.amountReceive,
        trade.payoutCurrency,
      ),
      fundingAddress: responseData.serverAddress,
      payoutAddress: responseData.recipient,
      refundAddress: _nonEmpty(responseData.refundAddress),
      outputTransaction: _nonEmpty(responseData.outgoingTx),
      isRefund: responseData.status == TradeState.refunded,
    );
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      default:
        return currency.title.toUpperCase();
    }
  }

  Future<List<SwapTradeCoin>> _fetchCoins() async {
    final response = await _api.send(const SwapTradeCoinsRequest());

    if (response.success == false) {
      throw Exception(response.errors?.firstOrNull?.msg ?? response.msg ?? "coins unavailable");
    }

    return response.data ?? const [];
  }

  SwapTradeCoin? _coinFor(CryptoCurrency currency, List<SwapTradeCoin> coins) =>
      coins.firstWhereOrNull((c) => c.id.toUpperCase() == _normalizeCurrency(currency));

  String _networkFor(CryptoCurrency currency, List<SwapTradeCoin> coins) {
    final network = currency.network.toUpperCase();
    final supported = _coinFor(currency, coins)?.network.map((n) => n.toUpperCase()) ?? const [];

    if (!supported.contains(network)) {
      throw Exception("SwapTrade has no $network network for ${currency.title}");
    }

    return network;
  }

  ExchangeLimits _limitsFor(CryptoCurrency from, List<SwapTradeCoin> coins) {
    final coin = _coinFor(from, coins);

    if (coin == null) {
      throw Exception("${from.title} unsupported");
    }

    return ExchangeLimits(min: Money.trySafeParse(coin.min, from), max: Money.trySafeParse(coin.max, from));
  }

  String? _nonEmpty(String? value) => (value?.isEmpty ?? true) ? null : value;
}
