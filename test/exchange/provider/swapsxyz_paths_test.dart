import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "fakes.dart";
import "mock_proxy_wrapper.dart";
import "mocks/canned_responses.dart";

class _PathsMock extends MockProxyWrapper {
  _PathsMock({this.pairPaths = swapsXyzPairPaths, this.tokenPaths = swapsXyzTokenPaths});

  final String pairPaths;
  final String tokenPaths;

  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/api/getChainList" => const MockResponse(swapsXyzChainList),
    "/api/getPaths" => request.query.containsKey("dstChainId")
        ? MockResponse(pairPaths)
        : MockResponse(tokenPaths),
    "/api/getQuote" => const MockResponse(swapsXyzQuote),
    _ => null,
  };
}

void main() {
  test("token cache built from the schema resolves the native source and the listed token", () async {
    final mock = _PathsMock();
    final provider = SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock);

    await provider.fetchRate(
      FloatingRateRequest(
        depositAmount: Money.parse("2", CryptoCurrency.eth),
        payoutCurrency: CryptoCurrency.usdterc20,
      ),
    );

    final quote = mock.requestsTo("/api/getQuote").single;
    expect(quote.query["srcToken"], swapsXyzNativeAddress);
    expect(quote.query["dstToken"], swapsXyzUsdtAddress);
    expect(quote.query["swapDirection"], "exact-amount-in");
    expect(quote.query["amount"], "2000000000000000000");
  });

  test("fixed rate is rejected when the picked path has no exact-amount-out", () async {
    final provider = SwapsXyzExchangeProvider(
      settingsStore: FakeSettingsStore(),
      proxyWrapper: _PathsMock(),
    );

    await expectLater(
      provider.fetchRate(
        FixedRateRequest(
          depositCurrency: CryptoCurrency.eth,
          payoutAmount: Money.parse("2", CryptoCurrency.usdterc20),
        ),
      ),
      throwsA(predicate((e) => e.toString().contains("exact-amount-out"))),
    );
  });

  test("fixed rate gets past the picked path when it supports exact-amount-out", () async {
    final mock = _PathsMock(
      pairPaths: swapsXyzPairPaths.replaceAll(
        '"supportsExactAmountOut":false',
        '"supportsExactAmountOut":true',
      ),
    );
    final provider = SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock);

    await provider.fetchRate(
      FixedRateRequest(
        depositCurrency: CryptoCurrency.eth,
        payoutAmount: Money.parse("2", CryptoCurrency.usdterc20),
      ),
    );

    final quote = mock.requestsTo("/api/getQuote").single;
    expect(quote.query["srcToken"], swapsXyzNativeAddress);
    expect(quote.query["dstToken"], swapsXyzUsdtAddress);
    expect(quote.query["swapDirection"], "exact-amount-out");
    expect(quote.query["amount"], "2000000");
  });

  test("an \"all\" tokens path still lets the native token resolve", () async {
    final mock = _PathsMock(tokenPaths: swapsXyzPairPaths);
    final provider = SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock);

    await provider.fetchRate(
      FloatingRateRequest(
        depositAmount: Money.parse("2", CryptoCurrency.eth),
        payoutCurrency: CryptoCurrency.usdterc20,
      ),
    );

    expect(mock.requestsTo("/api/getQuote").single.query["srcToken"], swapsXyzNativeAddress);
  });
}
