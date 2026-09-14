import "package:cake_wallet/exchange/provider/swaptrade/swaptrade_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class SwapTradeMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) => switch ((request.method, request.path)) {
    ("GET", "/api/swap/get-coins") => const MockResponse(swapTradeCoins),
    ("POST", "/api/swap/get-rate") => const MockResponse(swapTradeRate),
    ("POST", "/api/swap/create-order") => const MockResponse(swapTradeCreateOrder),
    ("POST", "/api/swap/order") => (request.body ?? "").contains(swapTradeTradeId)
        ? const MockResponse(swapTradeOrder)
        : const MockResponse.badRequest(swapTradeOrderNotFound),
    _ => null,
  };
}

ProviderScenario swapTradeScenario() => ProviderScenario(
  title: "SwapTrade",
  build: () {
    final mock = SwapTradeMockProxyWrapper();
    return ProviderUnderTest(SwapTradeExchangeProvider(proxyWrapper: mock), mock);
  },
  from: CryptoCurrency.btc,
  to: CryptoCurrency.xmr,
  depositAmount: Money.parse("2", CryptoCurrency.btc),
  payoutAmount: Money.parse("500", CryptoCurrency.xmr),
  isFixedRate: false,
  expectedLimitsMin: Money.parse("0.001", CryptoCurrency.btc),
  expectedLimitsMax: Money.parse("20", CryptoCurrency.btc),
  // SwapTrade quotes a unit price directly rather than an output for an input
  expectedRateQuote: Money.parse("250", CryptoCurrency.xmr),
  expectedRateLimitsMin: Money.parse("0.001", CryptoCurrency.btc),
  expectedRateLimitsMax: Money.parse("20", CryptoCurrency.btc),
  expectedCreatedTrade: ExpectedTrade(
    id: swapTradeTradeId,
    state: TradeState.created,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: swapTradeServerAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    createdAtIsNow: true,
  ),
  tradeId: swapTradeTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: swapTradeTradeId,
    // "5" is SwapTrade's numeric status for a swap in flight
    state: TradeState.exchanging,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: swapTradeServerAddress,
    payoutAddress: "payout-address",
    refundAddress: "",
    memo: "st-memo",
    createdAt: DateTime.parse(swapTradeCreatedAt),
  ),
  unknownTradeIdThrows: isA<Exception>(),
);
