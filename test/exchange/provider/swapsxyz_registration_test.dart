import "dart:convert";
import "dart:math";

import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_api_schema.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "fakes.dart";
import "mock_proxy_wrapper.dart";
import "mocks/canned_responses.dart";
import "mocks/swapsxyz_mock.dart";

class _RegistrationMock extends SwapsXyzMockProxyWrapper {
  _RegistrationMock({this.accepts = const [true], this.action = const {}});

  // registerTxs answers these in turn, the last one for good
  final List<bool> accepts;

  final Map<String, dynamic> action;

  int _registrations = 0;

  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/api/registerTxs" => _register(),
    "/api/getAction" => MockResponse(
      jsonEncode({...jsonDecode(swapsXyzAction) as Map<String, dynamic>, ...action}),
    ),
    _ => super.route(request),
  };

  MockResponse _register() {
    final accepted = accepts[min(_registrations++, accepts.length - 1)];
    // what api-v2 answers, an array even for a single-object body
    return MockResponse(
      jsonEncode([
        {
          "txId": "0xtxid",
          "success": accepted,
          "error": accepted ? null : "Failed to register transaction",
        },
      ]),
    );
  }
}

SwapsXyzExchangeProvider _provider(MockProxyWrapper mock, {List<Duration> retries = const []}) =>
    SwapsXyzExchangeProvider(
      settingsStore: FakeSettingsStore(),
      proxyWrapper: mock,
      registrationRetryDelays: retries,
    );

Future<SwapsXyzTrade> _create(_RegistrationMock mock) async =>
    await _provider(mock).createTrade(
          request: TradeRequest(
            refundAddress: "refund-address",
            payoutAddress: "payout-address",
            depositAmount: Money.parse("2", CryptoCurrency.eth),
            payoutAmount: Money.parse("4000", CryptoCurrency.usdterc20),
            isFixedRate: false,
          ),
        )
        as SwapsXyzTrade;

SwapsXyzTrade _swap({bool needToRegister = true}) => SwapsXyzTrade(
  id: "0xtxid",
  provider: ExchangeProviderDescription.swapsXyz,
  state: TradeState.created,
  depositAmount: Money.parse("0.01", CryptoCurrency.btc),
  payoutAmount: Money.parse("0.3", CryptoCurrency.eth),
  fundingAddress: "bc1qdeposit",
  payoutAddress: "payout-address",
  refundAddress: "refund-address",
  routerData: "",
  routerValue: "1000000",
  router: "999000313",
  vmId: SwapsXyzVmId.altVm,
  needToRegister: needToRegister,
  sourceTokenAddress: "",
  sourceTokenDecimals: 8,
  sourceTokenAmountRaw: "1000000",
  requiresTokenApproval: false,
);

void main() {
  group("createTrade", () {
    test("an evm deposit bridging out to an alt-vm chain is registered", () async {
      // what getAction answers for ETH -> BTC: an evm tx, flagged
      final trade = await _create(
        _RegistrationMock(action: {"vmId": "evm", "requiresRegisterTransaction": true}),
      );

      expect(trade.needToRegister, isTrue);
    });

    test("an alt-vm deposit is registered", () async {
      final trade = await _create(
        _RegistrationMock(action: {"vmId": "alt-vm", "requiresRegisterTransaction": false}),
      );

      expect(trade.needToRegister, isTrue);
    });

    test("an alt-vm-* bridge is registered", () async {
      final trade = await _create(
        _RegistrationMock(
          action: {
            "requiresRegisterTransaction": false,
            "bridgeIds": ["alt-vm-near"],
          },
        ),
      );

      expect(trade.needToRegister, isTrue);
    });

    test("a same-chain evm swap isn't", () async {
      final trade = await _create(_RegistrationMock());

      expect(trade.needToRegister, isFalse);
    });
  });

  group("registerTransaction", () {
    test("sends the txId and txHash the docs ask for, nothing else", () async {
      final mock = _RegistrationMock();
      final trade = _swap();

      final registered = await _provider(mock).registerTransaction(trade, "0xhash");

      final request = mock.requestsTo("/api/registerTxs").single;
      expect(request.method, "POST");
      expect(jsonDecode(request.body!), {"txId": "0xtxid", "txHash": "0xhash"});
      expect(registered, same(trade), reason: "registration doesn't change the trade");
    });

    test("leaves routes that don't need registering alone", () async {
      final mock = _RegistrationMock();
      final trade = _swap(needToRegister: false);

      final registered = await _provider(mock).registerTransaction(trade, "0xhash");

      expect(mock.requests, isEmpty);
      expect(registered, same(trade));
    });

    test("retries until swaps.xyz has seen the tx", () async {
      final mock = _RegistrationMock(accepts: [false, false, true]);

      await _provider(
        mock,
        retries: [Duration.zero, Duration.zero, Duration.zero],
      ).registerTransaction(_swap(), "0xhash");

      expect(mock.requestsTo("/api/registerTxs"), hasLength(3));
    });

    test("throws once the retries run out", () async {
      final mock = _RegistrationMock(accepts: [false]);

      await expectLater(
        _provider(mock, retries: [Duration.zero]).registerTransaction(_swap(), "0xhash"),
        throwsA(predicate((e) => e.toString().contains("Failed to register transaction"))),
      );
      expect(mock.requestsTo("/api/registerTxs"), hasLength(2));
    });
  });
}
