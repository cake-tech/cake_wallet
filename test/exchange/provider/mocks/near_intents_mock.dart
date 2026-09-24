import "package:cake_wallet/exchange/provider/near_intents/near_Intents_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class NearIntentsMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) {
    if (request.method == "GET" && request.path == "/v0/tokens") {
      return const MockResponse(nearTokens);
    }

    if (request.method == "POST" && request.path == "/v0/quote") {
      // a dry quote prices the pair, a live one reserves a deposit address
      return (request.body ?? "").contains('"dry":true')
          ? MockResponse.created(nearDryQuote)
          : MockResponse.created(nearLiveQuote);
    }

    if (request.method == "GET" && request.path == "/v0/status") {
      return request.query["depositAddress"] == nearDepositAddress
          ? MockResponse(nearStatus)
          : const MockResponse.notFound(nearNotFound);
    }

    return null;
  }
}

ProviderScenario nearIntentsScenario() => ProviderScenario(
  title: "Near Intents",
  build: () {
    final mock = NearIntentsMockProxyWrapper();
    return ProviderUnderTest(NearIntentsExchangeProvider(proxyWrapper: mock), mock);
  },
  from: CryptoCurrency.btc,
  to: CryptoCurrency.zec,
  depositAmount: Money.parse("2", CryptoCurrency.btc),
  payoutAmount: Money.parse("500", CryptoCurrency.zec),
  isFixedRate: false,
  // 1click prices every quote individually and publishes no bounds, so an unconstrained
  // ExchangeLimits is the honest answer rather than a missing feature
  expectedLimitsMin: null,
  expectedLimitsMax: null,
  expectedRateQuote: Money.parse("250", CryptoCurrency.zec),
  expectedRateLimitsMin: null,
  expectedRateLimitsMax: null,
  expectedCreatedTrade: ExpectedTrade(
    // the deposit address is the trade
    id: nearDepositAddress,
    state: TradeState.created,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.zec),
    fundingAddress: nearDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    createdAtIsNow: true,
  ),
  tradeId: nearDepositAddress,
  expectedFoundTrade: ExpectedTrade(
    id: nearDepositAddress,
    state: TradeState.processing,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.zec),
    fundingAddress: nearDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    txId: "near-origin-tx",
    isRefund: false,
  ),
  unknownTradeIdThrows: isA<Exception>(),
);
