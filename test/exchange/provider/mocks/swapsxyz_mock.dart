import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../fakes.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class SwapsXyzMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/api/getChainList" => const MockResponse(swapsXyzChainList),
    "/api/getPaths" => request.query.containsKey("dstChainId")
        ? const MockResponse(swapsXyzPairPaths)
        : const MockResponse(swapsXyzTokenPaths),
    "/api/getQuote" => const MockResponse(swapsXyzQuote),
    "/api/getAction" => const MockResponse(swapsXyzAction),
    "/api/getStatus" => request.query["txId"] == swapsXyzTxId
        ? const MockResponse(swapsXyzStatus)
        : const MockResponse.notFound(swapsXyzNotFound),
    _ => null,
  };
}

ProviderScenario swapsXyzScenario() => ProviderScenario(
  title: "Swaps.XYZ",
  build: () {
    final mock = SwapsXyzMockProxyWrapper();
    return ProviderUnderTest(
      SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock),
      mock,
    );
  },
  from: CryptoCurrency.eth,
  to: CryptoCurrency.usdterc20,
  depositAmount: Money.parse("2", CryptoCurrency.eth),
  payoutAmount: Money.parse("4000", CryptoCurrency.usdterc20),
  isFixedRate: false,
  expectedLimitsMin: Money.parse("0.01", CryptoCurrency.eth),
  expectedLimitsMax: Money.parse("100", CryptoCurrency.eth),
  expectedRateQuote: Money.parse("2000", CryptoCurrency.usdterc20),
  expectedRateLimitsMin: Money.parse("0.01", CryptoCurrency.eth),
  expectedRateLimitsMax: Money.parse("100", CryptoCurrency.eth),
  expectedCreatedTrade: ExpectedTrade(
    id: swapsXyzTxId,
    state: TradeState.created,
    depositAmount: Money.parse("2", CryptoCurrency.eth),
    payoutAmount: Money.parse("4000", CryptoCurrency.usdterc20),
    // there is no deposit address in a router swap - the wallet signs a call to the router
    fundingAddress: swapsXyzRouter,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    providerId: "evm",
    createdAtIsNow: true,
  ),
  tradeId: swapsXyzTxId,
  expectedFoundTrade: ExpectedTrade(
    id: swapsXyzTxId,
    state: TradeState.pending,
    depositAmount: Money.parse("2", CryptoCurrency.eth),
    // the status body has no chain id on the payout token, so the provider resolves the
    // bare "USDT" ticker, which lands on omni usdt rather than the erc20 one. same
    // decimals, so the amount is right and only the label is off
    payoutAmount: Money.parse("4000", CryptoCurrency.usdt),
    fundingAddress: swapsXyzRouter,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    txId: "0xswapsxyzsrctx",
    createdAt: DateTime.fromMillisecondsSinceEpoch(swapsXyzTimestamp * 1000, isUtc: true),
  ),
  unknownTradeIdThrows: isA<Exception>(),
);
