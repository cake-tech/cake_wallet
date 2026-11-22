import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "fakes.dart";
import "mock_proxy_wrapper.dart";
import "mocks/canned_responses.dart";

const _circleUsdcOp = "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85";
const _bridgedUsdcOp = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607";

// The provider keeps the chain list in a static, so every test in this file shares one
const _chainList = '[{"chainId":1,"name":"Ethereum","vmId":"evm"},'
    '{"chainId":10,"name":"Optimism","vmId":"evm"}]';

const _noTokens = '{"tokens":[]}';

const _optimismBridgedUsdcFirst = '{"tokens":['
    '{"chainId":10,"address":"$_bridgedUsdcOp","name":"USD Coin","symbol":"USDC",'
    '"decimals":6,"isNative":false},'
    '{"chainId":10,"address":"$_circleUsdcOp","name":"USD Coin","symbol":"USDC",'
    '"decimals":6,"isNative":false}]}';

class _PathsMock extends MockProxyWrapper {
  _PathsMock({
    this.pairPaths = swapsXyzPairPaths,
    this.tokenPaths = swapsXyzTokenPaths,
    this.tokenLists = const {},
  });

  final String pairPaths;
  final String tokenPaths;
  final Map<String, String> tokenLists;

  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/api/getChainList" => const MockResponse(_chainList),
    "/api/getTokenList" => MockResponse(tokenLists[request.query["chainId"]] ?? _noTokens),
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

  test("USDC on Optimism is Circle's even when the bridged USDC.e is listed first", () async {
    final mock = _PathsMock(tokenLists: {"10": _optimismBridgedUsdcFirst});
    final provider = SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock);

    await provider.fetchRate(
      FloatingRateRequest(
        depositAmount: Money.parse("2", CryptoCurrency.eth),
        payoutCurrency: CryptoCurrency.usdcOp,
      ),
    );

    expect(mock.requestsTo("/api/getQuote").single.query["dstToken"], _circleUsdcOp);
  });
}
