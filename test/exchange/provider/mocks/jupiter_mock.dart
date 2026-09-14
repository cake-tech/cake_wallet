import "package:cake_wallet/exchange/provider/jupiter/jupiter_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class JupiterMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) {
    if (request.method == "GET" && request.path == "/ultra/v1/order") {
      // without a taker the endpoint only prices the swap; with one it also builds the
      // transaction the wallet has to sign
      return MockResponse(jupiterOrder(withTaker: request.query.containsKey("taker")));
    }

    return null;
  }
}

ProviderScenario jupiterScenario() => ProviderScenario(
  title: "Jupiter",
  build: () {
    final mock = JupiterMockProxyWrapper();
    return ProviderUnderTest(JupiterExchangeProvider(proxyWrapper: mock), mock);
  },
  from: CryptoCurrency.sol,
  to: CryptoCurrency.usdcsol,
  depositAmount: Money.parse("2", CryptoCurrency.sol),
  payoutAmount: Money.parse("400", CryptoCurrency.usdcsol),
  isFixedRate: false,
  // the ultra api validates amounts per order instead of publishing limits
  expectedLimitsMin: null,
  expectedLimitsMax: null,
  expectedRateQuote: Money.parse("200", CryptoCurrency.usdcsol),
  expectedRateLimitsMin: null,
  expectedRateLimitsMax: null,
  expectedCreatedTrade: ExpectedTrade(
    // the order's request id is the handle for signing and executing later
    id: jupiterRequestId,
    state: TradeState.created,
    depositAmount: Money.parse("2", CryptoCurrency.sol),
    payoutAmount: Money.parse("400", CryptoCurrency.usdcsol),
    // an on-chain swap has nothing to deposit into
    fundingAddress: "",
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    createdAtIsNow: true,
  ),
  tradeId: jupiterRequestId,
  // the ultra api has no lookup by order id: status lives on chain, under the signature the
  // wallet gets after broadcasting
  expectedFoundTrade: null,
  findTradeByIdThrows: isA<Exception>(),
);
