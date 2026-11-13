import "package:cake_wallet/exchange/provider/whynot/whynot_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class WhyNotMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) {
    if (request.method == "POST" && request.path == "/api/v1/info") {
      return const MockResponse(whyNotInfo);
    }

    if (request.method == "POST" && request.path == "/api/v1/transaction") {
      return const MockResponse(whyNotTransaction);
    }

    if (request.method == "GET" && request.path.startsWith("/api/v1/transaction/")) {
      return request.path.endsWith("/$whyNotTradeId")
          ? const MockResponse(whyNotTransaction)
          : const MockResponse.notFound(whyNotNotFound);
    }

    return null;
  }
}

ProviderScenario whyNotScenario() => ProviderScenario(
  title: "WhyNot",
  build: () {
    final mock = WhyNotMockProxyWrapper();
    return ProviderUnderTest(WhyNotExchangeProvider(proxyWrapper: mock), mock);
  },
  from: CryptoCurrency.usdterc20,
  to: CryptoCurrency.usdc,
  depositAmount: Money.parse("100", CryptoCurrency.usdterc20),
  payoutAmount: Money.parse("99", CryptoCurrency.usdc),
  isFixedRate: false,
  expectedLimitsMin: Money.parse("10", CryptoCurrency.usdterc20),
  expectedLimitsMax: Money.parse("50000", CryptoCurrency.usdterc20),
  expectedRateQuote: Money.parse("0.99", CryptoCurrency.usdc),
  expectedRateLimitsMin: Money.parse("10", CryptoCurrency.usdterc20),
  expectedRateLimitsMax: Money.parse("50000", CryptoCurrency.usdterc20),
  expectedCreatedTrade: ExpectedTrade(
    id: whyNotTradeId,
    state: TradeState.wait,
    depositAmount: Money.parse("100", CryptoCurrency.usdterc20),
    payoutAmount: Money.parse("99", CryptoCurrency.usdc),
    fundingAddress: whyNotDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    createdAtIsNow: true,
    expiredAt: DateTime.fromMillisecondsSinceEpoch(
      whyNotExpiredAtSeconds * 1000,
      isUtc: true,
    ),
  ),
  tradeId: whyNotTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: whyNotTradeId,
    state: TradeState.wait,
    depositAmount: Money.parse("100", CryptoCurrency.usdterc20),
    payoutAmount: Money.parse("99", CryptoCurrency.usdc),
    fundingAddress: whyNotDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    isRefund: false,
  ),
  unknownTradeIdThrows: isA<Exception>(),
);
