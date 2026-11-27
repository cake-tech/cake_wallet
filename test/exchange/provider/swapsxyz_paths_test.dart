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
const _usdt0Op = "0x01bFF41798a0BcF287b996046Ca68b395DbC1071";
const _legacyUsdtOp = "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58";
const _circleUsdcSui =
    "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC";

// The provider keeps the chain list in a static, so every test in this file shares one
const _chainList = '[{"chainId":1,"name":"Ethereum","vmId":"evm"},'
    '{"chainId":10,"name":"Optimism","vmId":"evm"},'
    '{"chainId":999000938,"name":"sui","vmId":"alt-vm"}]';

const _noTokens = '{"tokens":[]}';

const _optimismBridgedUsdcFirst = '{"tokens":['
    '{"chainId":10,"address":"$_bridgedUsdcOp","name":"USD Coin","symbol":"USDC",'
    '"decimals":6,"isNative":false},'
    '{"chainId":10,"address":"$_circleUsdcOp","name":"USD Coin","symbol":"USDC",'
    '"decimals":6,"isNative":false}]}';

const _optimismLegacyUsdt = '{"tokens":['
    '{"chainId":10,"address":"$_legacyUsdtOp","name":"Tether USD","symbol":"USDT",'
    '"decimals":6,"isNative":false}]}';

const _ethereumPathsWithOnlySuiNative = '{"srcChainId":1,"srcToken":{"chainId":1,'
    '"address":"$swapsXyzNativeAddress","name":"Ether","symbol":"ETH","decimals":18,'
    '"isNative":true},"paths":[{"chainId":999000938,"tokens":[{"chainId":999000938,'
    '"address":"0x2::sui::SUI","name":"Sui","symbol":"SUI","decimals":9,"isNative":true}],'
    '"supportsExactAmountIn":true,"supportsExactAmountOut":false}]}';

const _suiUsdc = '{"tokens":['
    '{"chainId":999000938,"address":"$_circleUsdcSui","name":"USDC","symbol":"USDC",'
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

  test("USDT on Optimism is USDT0 even though the legacy USDT is listed as \"USDT\"", () async {
    final mock = _PathsMock(tokenLists: {"10": _optimismLegacyUsdt});
    final provider = SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock);

    await provider.fetchRate(
      FloatingRateRequest(
        depositAmount: Money.parse("2", CryptoCurrency.eth),
        payoutCurrency: CryptoCurrency.usdtOp,
      ),
    );

    expect(mock.requestsTo("/api/getQuote").single.query["dstToken"], _usdt0Op);
  });

  test("USDC on Sui resolves even after other paths listed only native SUI", () async {
    final mock = _PathsMock(
      tokenPaths: _ethereumPathsWithOnlySuiNative,
      tokenLists: {"999000938": _suiUsdc},
    );
    final provider = SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock);

    for (final payout in [CryptoCurrency.usdterc20, CryptoCurrency.usdcSui]) {
      await provider.fetchRate(
        FloatingRateRequest(
          depositAmount: Money.parse("2", CryptoCurrency.eth),
          payoutCurrency: payout,
        ),
      );
    }

    expect(mock.requestsTo("/api/getQuote").last.query["dstToken"], _circleUsdcSui);
    expect(mock.requestsTo("/api/getTokenList").map((r) => r.query["chainId"]), ["1", "999000938"]);
  });
}
