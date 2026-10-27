import "package:cake_wallet/exchange/provider/trocador/trocador_exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "mock_proxy_wrapper.dart";

const _coin = '[{"name":"Bitcoin","ticker":"btc","network":"Mainnet","memo":false,'
    '"image":"","minimum":0.001,"maximum":20.0}]';

// the best quote overall is from a provider the user disabled, the next one is the fixed rate
// variant of a provider, so the quote the swap can actually use is only third
const _swapRate = '{"trade_id":"rate-id","date":"2026-10-19T14:24:53.108205Z",'
    '"ticker_from":"btc","ticker_to":"xmr","coin_from":"Bitcoin","coin_to":"Monero",'
    '"network_from":"Mainnet","network_to":"Mainnet","amount_from":2,"amount_to":520,'
    '"provider":"Disabled","fixed":false,"payment":false,"status":"new",'
    '"quotes":{"markup":true,"quotes":['
    '{"provider":"Disabled","fixed":"False","amount_to":"520","unadjusted_amount_to":530},'
    '{"provider":"FixedFloat","fixed":"True","amount_to":"510"},'
    '{"provider":"ETZ","fixed":"False","amount_to":"500","unadjusted_amount_to":508},'
    '{"provider":"FixedFloat","fixed":"False","amount_to":"490","unadjusted_amount_to":498}]}}';

const _paymentRate = '{"trade_id":"payment-rate-id","date":"2026-10-19T14:29:13.206250Z",'
    '"ticker_from":"btc","ticker_to":"xmr","coin_from":"Bitcoin","coin_to":"Monero",'
    '"network_from":"Mainnet","network_to":"Mainnet","amount_from":0.0075,"amount_to":1.0,'
    '"provider":"Disabled","fixed":true,"payment":true,"status":"new",'
    '"quotes":{"markup":true,"quotes":['
    '{"provider":"Disabled","fixed":"True","amount_from":"0.0075"},'
    '{"provider":"BitcoinVN","fixed":"True","amount_from":"0.008"}]}}';

// what a 25 usdt to sol swap looked like: exolix quotes best, then refuses the trade
const _crowdedRate = '{"trade_id":"rate-id","date":"2026-10-19T14:49:01.105982Z",'
    '"ticker_from":"btc","ticker_to":"xmr","coin_from":"Bitcoin","coin_to":"Monero",'
    '"network_from":"Mainnet","network_to":"Mainnet","amount_from":2,"amount_to":502,'
    '"provider":"Exolix","fixed":false,"payment":false,"status":"new",'
    '"quotes":{"markup":true,"quotes":['
    '{"provider":"Exolix","fixed":"False","amount_to":"502"},'
    '{"provider":"FixedFloat","fixed":"False","amount_to":"500"},'
    '{"provider":"BitcoinVN","fixed":"False","amount_to":"499"},'
    '{"provider":"ChangeNow","fixed":"False","amount_to":"480"}]}}';

String _trade({required String amountFrom, required String amountTo, String provider = "ETZ"}) =>
    '{"trade_id":"rate-id","date":"2026-10-19T14:26:13.408966Z","type":"api",'
    '"ticker_from":"btc","ticker_to":"xmr","coin_from":"Bitcoin","coin_to":"Monero",'
    '"network_from":"Mainnet","network_to":"Mainnet","amount_from":$amountFrom,'
    '"amount_to":$amountTo,"provider":"$provider","fixed":false,"payment":false,"status":"waiting",'
    '"address_provider":"bc1qdeposit","address_provider_memo":"","address_user":"payout-address",'
    '"address_user_memo":"","refund_address":"refund-address","refund_address_memo":"",'
    '"password":"","id_provider":"etz-id"}';

class _TrocadorMock extends MockProxyWrapper {
  _TrocadorMock({required this.rate, this.stored, this.refusals = const {}});

  final String rate;

  /// Sub-providers that turn new_trade down, with the status they answer it with.
  final Map<String, int> refusals;

  /// What /trade answers with, null to fail the lookup.
  final String? stored;

  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/coin" => const MockResponse(_coin),
    "/new_rate" => MockResponse(rate),
    "/new_trade" => switch (refusals[request.query["provider"]]) {
      final status? => MockResponse(
        '{"error":"trade could not be generated, some unknown error happened"}',
        statusCode: status,
      ),
      null => MockResponse(
        _trade(amountFrom: "2", amountTo: "497", provider: request.query["provider"]!),
      ),
    },
    "/trade" => stored == null
        ? const MockResponse('{"error":"Rate limit exceeded"}', statusCode: 429)
        : MockResponse("[$stored]"),
    _ => null,
  };
}

TrocadorExchangeProvider _provider(_TrocadorMock mock) =>
    TrocadorExchangeProvider(proxyWrapper: mock, providerStates: {"Disabled": false});

TradeRequest _request({bool isFixedRate = false}) => TradeRequest(
  refundAddress: "refund-address",
  payoutAddress: "payout-address",
  depositAmount: Money.parse("2", CryptoCurrency.btc),
  payoutAmount: Money.parse(isFixedRate ? "1" : "500", CryptoCurrency.xmr),
  isFixedRate: isFixedRate,
);

void main() {
  group("swap", () {
    test("the rate is the first enabled quote of the swap's rate type, not the best overall", () async {
      final rate = await _provider(_TrocadorMock(rate: _swapRate)).fetchRate(
        FloatingRateRequest(
          depositAmount: Money.parse("2", CryptoCurrency.btc),
          payoutCurrency: CryptoCurrency.xmr,
        ),
      );

      expect(rate.rate.convert(Money.parse("2", CryptoCurrency.btc)), Money.parse("500", CryptoCurrency.xmr));
    });

    test("the trade goes to that same quote, against the rate id", () async {
      final mock = _TrocadorMock(rate: _swapRate, stored: _trade(amountFrom: "2", amountTo: "497"));

      await _provider(mock).createTrade(request: _request());

      final query = mock.requestsTo("/new_trade").single.query;
      expect(query["id"], "rate-id");
      expect(query["provider"], "ETZ");
      expect(query["fixed"], "False");
      expect(query["payment"], "False");
      expect(query["amount_from"], "2");
      expect(query.containsKey("amount_to"), isFalse);
    });

    test("the trade names the trocador sub-provider", () async {
      final mock = _TrocadorMock(rate: _swapRate, stored: _trade(amountFrom: "2", amountTo: "497"));

      final trade = await _provider(mock).createTrade(request: _request());

      expect(trade.providerName, "ETZ");
    });

    test("the amounts are the ones trocador stored, not the new_trade response", () async {
      // trocador takes another 0.1% off an ETZ trade right after creating it
      final mock = _TrocadorMock(rate: _swapRate, stored: _trade(amountFrom: "2", amountTo: "496.503"));

      final trade = await _provider(mock).createTrade(request: _request());

      expect(mock.requestsTo("/trade").single.query["id"], "rate-id");
      expect(trade.depositAmount, Money.parse("2", CryptoCurrency.btc));
      expect(trade.payoutAmount, Money.parse("496.503", CryptoCurrency.xmr));
      expect(trade.providerName, "ETZ");
    });

    test("a failed read back keeps the new_trade amounts instead of failing the swap", () async {
      final trade = await _provider(_TrocadorMock(rate: _swapRate)).createTrade(request: _request());

      expect(trade.id, "rate-id");
      expect(trade.payoutAmount, Money.parse("497", CryptoCurrency.xmr));
      expect(trade.providerName, "ETZ");
    });

    test("no enabled quote of the right rate type means no rate", () async {
      const onlyFixed = '{"trade_id":"rate-id","ticker_from":"btc","ticker_to":"xmr",'
          '"coin_from":"Bitcoin","coin_to":"Monero","network_from":"Mainnet",'
          '"network_to":"Mainnet","amount_from":2,"amount_to":520,"provider":"Disabled",'
          '"status":"new","quotes":{"quotes":['
          '{"provider":"Disabled","fixed":"False","amount_to":"520"},'
          '{"provider":"FixedFloat","fixed":"True","amount_to":"510"}]}}';

      await expectLater(
        _provider(_TrocadorMock(rate: onlyFixed)).fetchRate(
          FloatingRateRequest(
            depositAmount: Money.parse("2", CryptoCurrency.btc),
            payoutCurrency: CryptoCurrency.xmr,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group("a sub-provider refusing the trade", () {
    test("moves on to the next quote, on the same rate id", () async {
      final mock = _TrocadorMock(rate: _crowdedRate, refusals: {"Exolix": 400});

      final trade = await _provider(mock).createTrade(request: _request());

      final attempts = mock.requestsTo("/new_trade").map((request) => request.query);
      expect(attempts.map((query) => query["provider"]), ["Exolix", "FixedFloat"]);
      expect(attempts.map((query) => query["id"]), everyElement("rate-id"));
      expect(trade.providerName, "FixedFloat");
    });

    test("anything but a refusal is not retried", () async {
      final mock = _TrocadorMock(rate: _crowdedRate, refusals: {"Exolix": 500});

      await expectLater(
        _provider(mock).createTrade(request: _request()),
        throwsA(isA<ProviderHttpException>().having((e) => e.statusCode, "statusCode", 500)),
      );
      expect(mock.requestsTo("/new_trade"), hasLength(1));
    });

    test("gives up after three sub-providers", () async {
      final mock = _TrocadorMock(
        rate: _crowdedRate,
        refusals: {"Exolix": 400, "FixedFloat": 400, "BitcoinVN": 400, "ChangeNow": 400},
      );

      await expectLater(
        _provider(mock).createTrade(request: _request()),
        throwsA(isA<ProviderHttpException>()),
      );
      expect(
        mock.requestsTo("/new_trade").map((request) => request.query["provider"]),
        ["Exolix", "FixedFloat", "BitcoinVN"],
      );
    });
  });

  group("payment", () {
    test("the rate comes from the quote's amount_from", () async {
      final rate = await _provider(_TrocadorMock(rate: _paymentRate)).fetchRate(
        FixedRateRequest(
          depositCurrency: CryptoCurrency.btc,
          payoutAmount: Money.parse("1", CryptoCurrency.xmr),
        ),
      );

      expect(rate.rate.convert(Money.parse("1", CryptoCurrency.xmr)), Money.parse("0.008", CryptoCurrency.btc));
    });

    test("the trade asks for the payout amount at a fixed rate, against the rate id", () async {
      final mock = _TrocadorMock(rate: _paymentRate, stored: _trade(amountFrom: "0.008", amountTo: "1"));

      await _provider(mock).createTrade(request: _request(isFixedRate: true));

      final query = mock.requestsTo("/new_trade").single.query;
      expect(query["id"], "payment-rate-id");
      expect(query["provider"], "BitcoinVN");
      expect(query["fixed"], "True");
      expect(query["payment"], "True");
      expect(query["amount_to"], "1");
      expect(query.containsKey("amount_from"), isFalse);
    });
  });
}
