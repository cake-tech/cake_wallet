import "dart:convert";

import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_api_schema.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "fakes.dart";
import "mock_proxy_wrapper.dart";

class _RegistrationMock extends MockProxyWrapper {
  _RegistrationMock({this.accepted = true});

  final bool accepted;

  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/api/registerTxs" => MockResponse(jsonEncode([{"success": accepted}])),
    _ => null,
  };
}

SwapsXyzTrade _trade({bool needToRegister = true, String? router = "1"}) => SwapsXyzTrade(
  id: "0xtxid",
  provider: ExchangeProviderDescription.swapsXyz,
  state: TradeState.created,
  depositAmount: Money.parse("2", CryptoCurrency.eth),
  payoutAmount: Money.parse("4000", CryptoCurrency.usdterc20),
  fundingAddress: "0xrouter",
  payoutAddress: "payout-address",
  refundAddress: "refund-address",
  routerData: "0x",
  routerValue: "0",
  router: router,
  vmId: SwapsXyzVmId.altVm,
  needToRegister: needToRegister,
  sourceTokenAddress: "",
  sourceTokenDecimals: 18,
  sourceTokenAmountRaw: "0",
  requiresTokenApproval: false,
);

SwapsXyzExchangeProvider _provider(MockProxyWrapper mock) =>
    SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock);

void main() {
  test("registers the broadcast tx under the trade's swaps.xyz id", () async {
    final mock = _RegistrationMock();
    final trade = _trade();

    final registered = await _provider(mock).registerTransaction(trade, "0xhash");

    final request = mock.requestsTo("/api/registerTxs").single;
    expect(jsonDecode(request.body!), {
      "txId": "0xtxid",
      "txHash": "0xhash",
      "vmId": "alt-vm",
      "chainId": 1,
    });
    expect(registered, same(trade), reason: "registration doesn't change the trade");
  });

  test("leaves routes that don't need registering alone", () async {
    final mock = _RegistrationMock();
    final trade = _trade(needToRegister: false);

    final registered = await _provider(mock).registerTransaction(trade, "0xhash");

    expect(mock.requests, isEmpty);
    expect(registered, same(trade));
  });

  test("throws when swaps.xyz refuses the tx", () async {
    await expectLater(
      _provider(_RegistrationMock(accepted: false)).registerTransaction(_trade(), "0xhash"),
      throwsA(isA<Exception>()),
    );
  });

  test("throws without asking swaps.xyz when the chain id isn't numeric", () async {
    final mock = _RegistrationMock();

    await expectLater(
      _provider(mock).registerTransaction(_trade(router: "solana"), "0xhash"),
      throwsA(isA<Exception>()),
    );
    expect(mock.requests, isEmpty);
  });
}
