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
      _ => json["msg"]?.toString(),
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
    final responseJSON = await _api.send(const SwapTradeCoinsRequest());

    final coinsInfo = responseJSON.data;

    if (coinsInfo == null) {
      throw Exception("coin unsupported");
    }

    final normalized = _normalizeCurrency(from);
    final coin = coinsInfo.firstWhereOrNull((c) => (c.id.toUpperCase()) == normalized);

    if (coin == null) {
      throw Exception("${from.title} unsupported");
    }

    return ExchangeLimits(min: Money.trySafeParse(coin.min, from), max: Money.trySafeParse(coin.max, from));
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

    final responseBody = await _api.send(
      SwapTradeGetPriceRequest(
        coinSend: _normalizeCurrency(request.depositCurrency),
        coinSendNetwork: _networkFor(request.depositCurrency),
        coinReceiveNetwork: _networkFor(request.payoutCurrency),
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
      limits: await fetchLimits(
        from: request.depositCurrency,
        to: request.payoutCurrency,
        isFixedRateMode: false,
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final responseBody = await _api.send(
      SwapTradeCreateOrderRequest(
        coinSend: _normalizeCurrency(request.depositCurrency),
        coinSendNetwork: _networkFor(request.depositCurrency),
        coinReceive: _normalizeCurrency(request.payoutCurrency),
        coinReceiveNetwork: _networkFor(request.payoutCurrency),
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
    );
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      default:
        return currency.title.toUpperCase();
    }
  }

  String _networkFor(CryptoCurrency currency) {
    final network = switch (currency) {
      CryptoCurrency.eth => "ETH",
      CryptoCurrency.bnb => "BNB_BSC",
      CryptoCurrency.usdterc20 => "USDT_ERC20",
      CryptoCurrency.usdttrc20 => "TRX_USDT_S2UZ",
      CryptoCurrency.usdtbsc => "USDT_BSC",
      CryptoCurrency.sol => "SOL",
      CryptoCurrency.btc => "BTC",
      CryptoCurrency.xmr => "XMR",
      CryptoCurrency.ltc => "LTC",
      CryptoCurrency.ada => "ADA",
      CryptoCurrency.bch => "BCH",
      CryptoCurrency.zec => "ZEC",
      _ => currency.title.toUpperCase(),
    };
    return network;
  }
}
