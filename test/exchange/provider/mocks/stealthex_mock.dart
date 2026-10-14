import "package:cake_wallet/exchange/provider/stealthex/stealth_ex_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class StealthExMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) {
    if (request.method == "POST" && request.path == "/v4/rates/range") {
      return const MockResponse(stealthExRange);
    }

    if (request.method == "POST" && request.path == "/v4/rates/estimated-amount") {
      return const MockResponse(stealthExEstimatedAmount);
    }

    if (request.method == "POST" && request.path == "/v4/exchanges") {
      return const MockResponse.created(stealthExExchange);
    }

    if (request.method == "GET" && request.path.startsWith("/v4/exchanges/")) {
      return request.path.endsWith("/$stealthExTradeId")
          ? const MockResponse(stealthExExchange)
          : const MockResponse.notFound(stealthExNotFound);
    }

    return null;
  }
}

ProviderScenario stealthExScenario() => ProviderScenario(
  title: "StealthEX",
  build: () {
    final mock = StealthExMockProxyWrapper();
    return ProviderUnderTest(StealthExExchangeProvider(proxyWrapper: mock), mock);
  },
  from: CryptoCurrency.btc,
  to: CryptoCurrency.xmr,
  depositAmount: Money.parse("2", CryptoCurrency.btc),
  payoutAmount: Money.parse("500", CryptoCurrency.xmr),
  isFixedRate: false,
  expectedLimitsMin: Money.parse("0.001", CryptoCurrency.btc),
  expectedLimitsMax: Money.parse("20", CryptoCurrency.btc),
  expectedRateQuote: Money.parse("250", CryptoCurrency.xmr),
  expectedRateLimitsMin: Money.parse("0.001", CryptoCurrency.btc),
  expectedRateLimitsMax: Money.parse("20", CryptoCurrency.btc),
  expectedCreatedTrade: ExpectedTrade(
    id: stealthExTradeId,
    state: TradeState.waiting,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: stealthExDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    toAddressExtraId: "",
    createdAt: DateTime.parse(stealthExCreatedAt).toLocal(),
    // a floating rate has no rate id to expire, so the provider invents a five minute window
    expiredAtIsNowPlus: const Duration(minutes: 5),
  ),
  tradeId: stealthExTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: stealthExTradeId,
    state: TradeState.waiting,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: stealthExDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    createdAt: DateTime.parse(stealthExCreatedAt),
    isRefund: false,
  ),
  unknownTradeIdThrows: isA<Exception>(),
);
