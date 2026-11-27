import "dart:convert";

import "package:cake_wallet/exchange/provider/whynot/whynot_exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/tron_token.dart";
import "package:flutter_test/flutter_test.dart";

import "mocks/whynot_mock.dart";

void main() {
  final excluded = <CryptoCurrency>[
    CryptoCurrency.usdtOp,
    CryptoCurrency.usddEth,
    CryptoCurrency.usddTrx,
    Erc20Token(
      name: "USDD",
      symbol: "USDD",
      contractAddress: "0x4f8e5de400de08b164e7421b3ee387f461becd1a",
      decimal: 18,
      tag: "ETH",
    ),
    TronToken(
      name: "USDD",
      symbol: "USDD",
      contractAddress: "TXDk8mbtRbXeYuMNS83CfKPaYYT8XWv9Hz",
      decimal: 18,
    ),
  ];

  for (final coin in excluded) {
    test("${coin.title} on ${coin.tag} (${coin.runtimeType}) never reaches WhyNot", () async {
      for (final (from, to) in [(coin, CryptoCurrency.btc), (CryptoCurrency.btc, coin)]) {
        final mock = WhyNotMockProxyWrapper();
        final provider = WhyNotExchangeProvider(proxyWrapper: mock);

        await expectLater(
          provider.fetchRate(
            FloatingRateRequest(depositAmount: Money.parse("100", from), payoutCurrency: to),
          ),
          throwsException,
        );
        await expectLater(
          provider.fetchLimits(from: from, to: to, isFixedRateMode: false),
          throwsException,
        );
        await expectLater(
          provider.createTrade(
            request: TradeRequest(
              depositAmount: Money.parse("100", from),
              payoutAmount: Money.parse("100", to),
              refundAddress: "refund-address",
              payoutAddress: "payout-address",
              isFixedRate: false,
            ),
          ),
          throwsException,
        );

        expect(mock.requests, isEmpty);
      }
    });
  }

  test("USDT on Ethereum still reaches WhyNot", () async {
    final mock = WhyNotMockProxyWrapper();
    await WhyNotExchangeProvider(proxyWrapper: mock).fetchRate(
      FloatingRateRequest(
        depositAmount: Money.parse("100", CryptoCurrency.usdterc20),
        payoutCurrency: CryptoCurrency.btc,
      ),
    );

    expect(mock.requestsTo("/api/v1/info"), hasLength(1));
  });

  test("USDC on Optimism goes to WhyNot as OPTIMISM", () async {
    final mock = WhyNotMockProxyWrapper();
    await WhyNotExchangeProvider(proxyWrapper: mock).fetchRate(
      FloatingRateRequest(
        depositAmount: Money.parse("100", CryptoCurrency.usdcOp),
        payoutCurrency: CryptoCurrency.btc,
      ),
    );

    final request = mock.requestsTo("/api/v1/info").single;
    expect((json.decode(request.body!) as Map<String, dynamic>)["network_from"], "OPTIMISM");
  });
}
