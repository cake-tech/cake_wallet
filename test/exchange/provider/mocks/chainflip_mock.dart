import "package:cake_wallet/exchange/provider/chainflip/chainflip_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class ChainflipMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/assets" => const MockResponse(chainflipAssets),
    "/quotes-native" => const MockResponse(chainflipQuotes),
    "/swap" => const MockResponse(chainflipSwap),
    "/status-by-deposit-channel" =>
      request.query["channelId"] == "$chainflipChannelId"
          ? const MockResponse(chainflipStatus)
          : const MockResponse.notFound(""),
    _ => null,
  };
}

ProviderScenario chainflipScenario() => ProviderScenario(
  title: "Chainflip",
  build: () {
    final mock = ChainflipMockProxyWrapper();
    return ProviderUnderTest(ChainflipExchangeProvider(proxyWrapper: mock), mock);
  },
  from: CryptoCurrency.btc,
  to: CryptoCurrency.eth,
  depositAmount: Money.parse("2", CryptoCurrency.btc),
  payoutAmount: Money.parse("60", CryptoCurrency.eth),
  isFixedRate: false,
  // Chainflip publishes a floor per asset and no ceiling
  expectedLimitsMin: Money.parse("0.001", CryptoCurrency.btc),
  expectedLimitsMax: null,
  expectedRateQuote: Money.parse("30", CryptoCurrency.eth),
  expectedRateLimitsMin: Money.parse("0.001", CryptoCurrency.btc),
  expectedRateLimitsMax: null,
  expectedCreatedTrade: ExpectedTrade(
    // the deposit channel is the trade: block, network and channel id
    id: chainflipTradeId,
    state: TradeState.waiting,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("60", CryptoCurrency.eth),
    fundingAddress: chainflipDepositAddress,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    createdAtIsNow: true,
  ),
  tradeId: chainflipTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: chainflipTradeId,
    state: TradeState.processing,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("60", CryptoCurrency.eth),
    fundingAddress: chainflipDepositAddress,
    payoutAddress: "payout-address",
    // the deposit channel holds the refund address but the provider does not read it back
    refundAddress: "",
    outputTransaction: "cf-egress-tx",
    isRefund: false,
  ),
  unknownTradeId: "$chainflipIssuedBlock-bitcoin-999999",
  unknownTradeIdThrows: isA<Exception>(),
);
