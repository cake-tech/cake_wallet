import "package:cake_wallet/exchange/provider/xoswap/xoswap_exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "mock_proxy_wrapper.dart";
import "mocks/canned_responses.dart";

const _tinymanUsdc = '{"id":"USDCTINY","symbol":"USDC","meta":{"assetIndex":"552647097"}}';
const _circleUsdc = '{"id":"USDCALGO","symbol":"USDC","meta":{"assetIndex":"31566704"}}';

class _AlgorandMock extends MockProxyWrapper {
  _AlgorandMock(this.assets);

  final String assets;

  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/v3/assets" => MockResponse(assets),
    _ when request.path.startsWith("/v3/pairs/") => const MockResponse(xoSwapPairRates),
    _ => null,
  };
}

void main() {
  test("USDC on Algorand is Circle's even when Tinyman's USDC is listed first", () async {
    final mock = _AlgorandMock("[$_tinymanUsdc,$_circleUsdc]");
    final provider = XOSwapExchangeProvider(proxyWrapper: mock);

    for (final (from, to) in [
      (CryptoCurrency.btc, CryptoCurrency.usdcAlgo),
      (CryptoCurrency.usdcAlgo, CryptoCurrency.btc),
    ]) {
      await provider.fetchRate(
        FloatingRateRequest(depositAmount: Money.parse("2", from), payoutCurrency: to),
      );
    }

    expect(mock.requests.where((r) => r.path.startsWith("/v3/pairs/")).map((r) => r.path), [
      "/v3/pairs/BTC_USDCALGO/rates",
      "/v3/pairs/USDCALGO_BTC/rates",
    ]);
  });

  test("USDC on Algorand gets no XOSwap route when Circle's USDC is not listed", () async {
    final mock = _AlgorandMock("[$_tinymanUsdc]");
    final provider = XOSwapExchangeProvider(proxyWrapper: mock);

    await expectLater(
      provider.fetchRate(
        FloatingRateRequest(
          depositAmount: Money.parse("2", CryptoCurrency.btc),
          payoutCurrency: CryptoCurrency.usdcAlgo,
        ),
      ),
      throwsException,
    );
    expect(mock.requests.where((r) => r.path.startsWith("/v3/pairs/")), isEmpty);
  });
}
