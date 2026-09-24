import "package:cake_wallet/exchange/provider/trocador/trocador_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../exchange_provider_suite.dart";
import "../mock_proxy_wrapper.dart";
import "canned_responses.dart";

class TrocadorMockProxyWrapper extends MockProxyWrapper {
  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    // the provider probes the onion authority with the same url before every real call,
    // so each of these is asked for twice per operation
    "/coin" => const MockResponse(trocadorCoin),
    "/new_rate" => const MockResponse(trocadorNewRate),
    "/new_trade" => const MockResponse(trocadorTrade),
    "/trade" => request.query["id"] == trocadorTradeId
        ? const MockResponse("[$trocadorTrade]")
        : const MockResponse.notFound("[]"),
    _ => null,
  };
}

ProviderScenario trocadorScenario() => ProviderScenario(
  title: "Trocador",
  build: () {
    final mock = TrocadorMockProxyWrapper();
    return ProviderUnderTest(TrocadorExchangeProvider(proxyWrapper: mock), mock);
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
  // Trocador is a meta-exchange: createTrade has to name a sub-provider, and the only place
  // that list gets filled in is fetchRate. without a rate first it throws on an empty list.
  warmUp: (provider) => provider.fetchRate(
    from: Money.parse("2", CryptoCurrency.btc),
    to: CryptoCurrency.xmr,
    isFixedRate: false,
  ),
  expectedCreatedTrade: ExpectedTrade(
    id: trocadorTradeId,
    state: TradeState.waiting,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: trocadorAddressProvider,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    extraId: "tr-memo",
    toAddressExtraId: "",
    password: "tr-password",
    providerId: "tr-provider-id",
    createdAt: DateTime.parse(trocadorDate).toLocal(),
  ),
  tradeId: trocadorTradeId,
  expectedFoundTrade: ExpectedTrade(
    id: trocadorTradeId,
    state: TradeState.waiting,
    depositAmount: Money.parse("2", CryptoCurrency.btc),
    payoutAmount: Money.parse("500", CryptoCurrency.xmr),
    fundingAddress: trocadorAddressProvider,
    payoutAddress: "payout-address",
    refundAddress: "refund-address",
    extraId: "tr-memo",
    password: "tr-password",
    providerId: "tr-provider-id",
    createdAt: DateTime.parse(trocadorDate).toLocal(),
  ),
  unknownTradeIdThrows: isA<Exception>(),
);
