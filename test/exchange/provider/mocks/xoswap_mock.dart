import "package:cake_wallet/exchange/provider/xoswap/xoswap_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class XOSwapMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) => switch ((request.method, request.path)) {
    ("GET", "/v3/pairs/BTC_XMR/rates") => const MockResponse(xoSwapPairRates),
    ("POST", "/v3/orders") => const MockResponse.created(xoSwapOrder),
    ("GET", "/v3/orders/$xoSwapTradeId") => const MockResponse(xoSwapOrder),
    ("GET", _) => request.path.startsWith("/v3/orders/")
        ? const MockResponse.notFound(xoSwapNotFound)
        : null,
    _ => null,
  };
}

ProviderScenario xoSwapScenario() => ProviderScenario(
  title: "XOSwap",
  build: () {
    final mock = XOSwapMockProxyWrapper();
    return ProviderUnderTest(XOSwapExchangeProvider(proxyWrapper: mock), mock);
  },
  from: CryptoCurrency.btc,
  to: CryptoCurrency.xmr,
  depositAmount: Money.parse("2", CryptoCurrency.btc),
  payoutAmount: Money.parse("500", CryptoCurrency.xmr),
  isFixedRate: false,
  // the widest window any single maker offers, not the intersection
  expectedLimitsMin: Money.parse("0.001", CryptoCurrency.btc),
  expectedLimitsMax: Money.parse("10", CryptoCurrency.btc),
  expectedRateQuote: Money.parse("250", CryptoCurrency.xmr),
  expectedRateLimitsMin: Money.parse("0.001", CryptoCurrency.btc),
  expectedRateLimitsMax: Money.parse("10", CryptoCurrency.btc),
  expectedCreatedTrade: ExpectedTrade(
    id: xoSwapTradeId,
    state: TradeState.processing,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: xoSwapPayInAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    toAddressExtraId: "",
    createdAt: DateTime.parse(xoSwapCreatedAt),
  ),
  tradeId: xoSwapTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: xoSwapTradeId,
    state: TradeState.processing,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: xoSwapPayInAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    createdAt: DateTime.parse(xoSwapCreatedAt),
  ),
  unknownTradeIdThrows: isA<Exception>(),
);
