import "package:cake_wallet/exchange/exchange_exceptions.dart";
import "package:cake_wallet/exchange/provider/changenow/changenow_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../fakes.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class ChangeNowMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) => switch ((request.method, request.path)) {
    ("GET", "/v2/exchange/range") => const MockResponse(changeNowRange),
    ("GET", "/v2/exchange/estimated-amount") => const MockResponse(changeNowEstimatedAmount),
    ("POST", "/v2/exchange") => const MockResponse(changeNowCreateExchange),
    ("GET", "/v2/exchange/by-id") => request.query["id"] == changeNowTradeId
        ? const MockResponse(changeNowById)
        : const MockResponse.notFound(changeNowNotFound),
    _ => null,
  };
}

ProviderScenario changeNowScenario() => ProviderScenario(
  title: "ChangeNOW",
  build: () {
    final mock = ChangeNowMockProxyWrapper();
    return ProviderUnderTest(
      ChangeNowExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock),
      mock,
    );
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
    id: changeNowTradeId,
    state: TradeState.created,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: changeNowPayinAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    createdAtIsNow: true,
  ),
  tradeId: changeNowTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: changeNowTradeId,
    state: TradeState.confirming,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    // the lookup only refreshes status and amounts, the addresses stay as the stored trade had them
    fundingAddress: "",
    payoutAddress: "",
    refundAddress: "",
    outputTransaction: "cn-payout-hash",
    createdAt: DateTime.parse(changeNowCreatedAt),
    expiredAt: DateTime.parse(changeNowValidUntil),
  ),
  unknownTradeIdThrows: isA<TradeNotFoundException>(),
);
