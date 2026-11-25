import "dart:convert";

import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "fakes.dart";
import "mock_proxy_wrapper.dart";

class _StatusMock extends MockProxyWrapper {
  _StatusMock(this.status);

  final Map<String, dynamic> status;

  @override
  MockResponse? route(MockRequest request) => switch (request.path) {
    "/api/getStatus" => MockResponse(jsonEncode(status)),
    _ => null,
  };
}

// what the trade monitor hands over: a plain trade read back from the db
Trade _trade() => Trade(
  id: "0xtxid",
  provider: ExchangeProviderDescription.swapsXyz,
  state: TradeState.created,
  depositAmount: Money.parse("25", CryptoCurrency.usdterc20),
  payoutAmount: Money.parse("0.0059", CryptoCurrency.eth),
  fundingAddress: "0xrouter",
  payoutAddress: "0xrecipient",
  refundAddress: "0xsender",
  createdAt: DateTime.now(),
);

Map<String, dynamic> _leg({
  required String txHash,
  required String toAddress,
  required String symbol,
  required int decimals,
  required String amount,
}) => {
  "txHash": txHash,
  "chainId": 1,
  "timestamp": 1760000000,
  "toAddress": toAddress,
  "value": "0",
  "revertReason": null,
  "paymentToken": {
    "name": symbol,
    "symbol": symbol,
    "decimals": decimals,
    "amount": amount,
    "chainId": 1,
    "isNative": symbol == "ETH",
    "tokenAddress": null,
    "swapsXyzCode": "code",
  },
};

Map<String, dynamic> _status(String status, {Map<String, dynamic>? srcTx, Map<String, dynamic>? dstTx}) => {
  "txId": "0xtxid",
  "status": status,
  "srcChainId": 1,
  "dstChainId": 1,
  "sender": "0xsender",
  "bridgeDetails": {"isBridge": false, "bridgeTime": 0, "txPath": []},
  "srcTx": srcTx,
  "dstTx": dstTx,
  "actionRequest": {
    "actionType": "swap-action",
    "sender": "0xsender",
    "srcChainId": 1,
    "srcToken": "0xdac17f958d2ee523a2206206994597c13d831ec7",
    "dstChainId": 1,
    "dstToken": "0x0000000000000000000000000000000000000000",
    "slippage": 300,
    "amount": "25000000",
    "recipient": "0xrecipient",
    "gasless": false,
  },
};

final _usdtLeg = _leg(
  txHash: "0xsrc",
  toAddress: "0xrouter",
  symbol: "USDT",
  decimals: 6,
  amount: "25000000",
);

final _ethLeg = _leg(
  txHash: "0xdst",
  toAddress: "0xrecipient",
  symbol: "ETH",
  decimals: 18,
  amount: "6000000000000000",
);

Future<Trade> _update(_StatusMock mock) =>
    SwapsXyzExchangeProvider(settingsStore: FakeSettingsStore(), proxyWrapper: mock)
        .updateTrade(_trade());

void main() {
  test("looks the swap up by its swaps.xyz id", () async {
    final mock = _StatusMock(_status("pending"));

    await _update(mock);

    expect(mock.requestsTo("/api/getStatus").single.query, {"txId": "0xtxid"});
  });

  test("a finished swap reads as done with what actually moved", () async {
    final trade = await _update(_StatusMock(_status("success", srcTx: _usdtLeg, dstTx: _ethLeg)));

    expect(trade.state, TradeState.success);
    expect(trade.txId, "0xsrc");
    expect(trade.depositAmount, Money.parse("25", CryptoCurrency.usdterc20));
    expect(trade.payoutAmount, Money.parse("0.006", CryptoCurrency.eth));
    expect(trade.fundingAddress, "0xrouter");
    expect(trade.payoutAddress, "0xrecipient");
  });

  test("a swap swaps.xyz hasn't seen land yet keeps what the trade already had", () async {
    final before = _trade();

    final trade = await _update(_StatusMock(_status("pending")));

    expect(trade.state, TradeState.pending);
    expect(trade.depositAmount, before.depositAmount);
    expect(trade.payoutAmount, before.payoutAmount);
    expect(trade.fundingAddress, before.fundingAddress);
    expect(trade.payoutAddress, before.payoutAddress);
    expect(trade.txId, isNull);
  });

  test("a leg counted in other decimals than ours is stored in ours", () async {
    final usdtIn18 = _leg(
      txHash: "0xsrc",
      toAddress: "0xrouter",
      symbol: "USDT",
      decimals: 18,
      amount: "25000000000000000000",
    );

    final trade = await _update(_StatusMock(_status("success", srcTx: usdtIn18, dstTx: _ethLeg)));

    expect(trade.depositAmount.amount, BigInt.from(25000000));
    expect(trade.depositAmount.decimals, CryptoCurrency.usdterc20.decimals);
  });
}
