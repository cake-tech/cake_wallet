import "package:cake_wallet/exchange/provider/exolix/exolix_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_not_found_exception.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class ExolixMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) {
    if (request.method == "GET" && request.path == "/api/v2/rate") {
      return request.query["amount"] == "1"
          ? const MockResponse(exolixUnitRate)
          : const MockResponse(exolixRate);
    }

    if (request.method == "POST" && request.path == "/api/v2/transactions") {
      return const MockResponse.created(exolixTransaction);
    }

    if (request.method == "GET" && request.path.startsWith("/api/v2/transactions/")) {
      return request.path.endsWith("/$exolixTradeId")
          ? const MockResponse(exolixTransaction)
          : const MockResponse.notFound(exolixNotFound);
    }

    return null;
  }
}

ProviderScenario exolixScenario() => ProviderScenario(
  title: "Exolix",
  build: () {
    final mock = ExolixMockProxyWrapper();
    return ProviderUnderTest(ExolixExchangeProvider(proxyWrapper: mock), mock);
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
    id: exolixTradeId,
    state: TradeState.created,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: exolixDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    toAddressExtraId: "",
    createdAtIsNow: true,
  ),
  tradeId: exolixTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: exolixTradeId,
    state: TradeState.confirmation,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: exolixDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    outputTransaction: "exolix-hash-out",
  ),
  unknownTradeIdThrows: isA<TradeNotFoundException>(),
);
