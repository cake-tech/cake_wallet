import "package:cake_wallet/exchange/provider/letsexchange/letsexchange_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class LetsExchangeMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) {
    if (request.method == "POST" && request.path == "/api/v1/info") {
      return const MockResponse(letsExchangeInfo);
    }

    if (request.method == "POST" && request.path == "/api/v1/transaction") {
      return const MockResponse(letsExchangeTransaction);
    }

    if (request.method == "GET" && request.path.startsWith("/api/v1/transaction/")) {
      return request.path.endsWith("/$letsExchangeTradeId")
          ? const MockResponse(letsExchangeTransaction)
          : const MockResponse.notFound(letsExchangeNotFound);
    }

    return null;
  }
}

ProviderScenario letsExchangeScenario() => ProviderScenario(
  title: "LetsExchange",
  build: () {
    final mock = LetsExchangeMockProxyWrapper();
    return ProviderUnderTest(LetsExchangeExchangeProvider(proxyWrapper: mock), mock);
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
    id: letsExchangeTradeId,
    state: TradeState.wait,
    depositAmount: Money.parse("100", CryptoCurrency.usdterc20),
    payoutAmount: Money.parse("99", CryptoCurrency.usdc),
    fundingAddress: letsExchangeDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    toAddressExtraId: "",
    createdAt: DateTime.parse(letsExchangeCreatedAt),
    expiredAt: DateTime.fromMillisecondsSinceEpoch(letsExchangeExpiredAtSeconds * 1000),
  ),
  tradeId: letsExchangeTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: letsExchangeTradeId,
    state: TradeState.wait,
    depositAmount: Money.parse("100", CryptoCurrency.usdterc20),
    payoutAmount: Money.parse("99", CryptoCurrency.usdc),
    fundingAddress: letsExchangeDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    isRefund: false,
  ),
  unknownTradeIdThrows: isA<Exception>(),
);
