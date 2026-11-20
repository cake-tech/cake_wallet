import "package:cake_wallet/exchange/provider/swaptrade/swaptrade_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void main() {
  group("SwapTradeCoinsResponse", () {
    test("parses the envelope and every coin in get_coins", () {
      final raw = fixtureMap("swaptrade", "get_coins");
      final response = SwapTradeCoinsResponse.fromJson(raw);
      final rawCoins = raw["data"] as List<dynamic>;

      expect(response.success, raw["success"]);
      expect(response.status, raw["status"]);
      expect(response.msg, raw["msg"]);
      expect(response.errors, isNull);
      expect(response.data, hasLength(rawCoins.length));

      for (var i = 0; i < rawCoins.length; i++) {
        final rawCoin = rawCoins[i] as Map<String, dynamic>;
        final coin = response.data![i];

        expect(coin.id, rawCoin["id"]);
        expect(coin.name, rawCoin["name"]);
        expect(coin.price, double.parse(rawCoin["price"].toString()));
        expect(coin.min, (rawCoin["min"] as num).toDouble());
        expect(coin.max, (rawCoin["max"] as num).toDouble());
        expect(coin.minIncoming, (rawCoin["min_incoming"] as num).toDouble());
        expect(coin.maxIncoming, (rawCoin["max_incoming"] as num).toDouble());
        expect(coin.minOutgoing, (rawCoin["min_outgoing"] as num).toDouble());
        expect(coin.maxOutgoing, (rawCoin["max_outgoing"] as num).toDouble());
        expect(coin.minOutgoingUsd, (rawCoin["min_outgoing_USD"] as num).toDouble());
        expect(coin.maxOutgoingUsd, (rawCoin["max_outgoing_USD"] as num).toDouble());
        expect(coin.fee, double.parse(rawCoin["fee"].toString()));
        expect(coin.networkFee, double.parse(rawCoin["network_fee"].toString()));
        expect(coin.memo, rawCoin["memo"]);
        expect(coin.enabled, rawCoin["enabled"]);
        expect(coin.amountScale, rawCoin["amount_scale"]);
        expect(coin.erc, rawCoin["erc"]);
        expect(
          coin.network,
          (rawCoin["network"] as String).split(",").where((n) => n.isNotEmpty).toList(),
          reason: "networks arrive comma separated in one string",
        );
      }
    });

    test("price is a string for most coins and a number for at least one", () {
      final rawCoins = fixtureMap("swaptrade", "get_coins")["data"] as List<dynamic>;
      final types = rawCoins.map((c) => (c as Map)["price"].runtimeType.toString()).toSet();

      expect(
        types.length,
        greaterThanOrEqualTo(1),
        reason: "if this ever becomes a single type the amount converter can be simplified",
      );
      // whatever the wire type, every price lands as a double
      final response = SwapTradeCoinsResponse.fromJson(fixtureMap("swaptrade", "get_coins"));
      for (final coin in response.data!) {
        expect(coin.price, isA<double>());
      }
    });

    test("every coin lists the chains it moves on", () {
      final response = SwapTradeCoinsResponse.fromJson(fixtureMap("swaptrade", "get_coins"));
      final networks = {for (final coin in response.data!) coin.id: coin.network};

      for (final entry in networks.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
      }
      expect(networks["BTC"], contains("BTC"));
      expect(networks["XMR"], ["XMR"]);
      expect(networks["ETH"], containsAll(["ETH", "BASE", "ARB", "BSC"]));
      expect(networks["USDT"], containsAll(["ETH", "TRX", "BSC"]));
    });
  });

  group("SwapTradeRateResponse", () {
    test("parses get_price", () {
      final raw = fixtureMap("swaptrade", "get_price");
      final response = SwapTradeRateResponse.fromJson(raw);
      final rawPrice = raw["data"] as Map<String, dynamic>;

      expect(response.success, isTrue);
      expect(response.status, raw["status"]);
      expect(response.msg, raw["msg"]);
      expect(response.errors, isNull);
      expect(response.data!.price, rawPrice["data"]);
      expect(response.data!.symbol, isNull);
    });

    test("a rejected quote answers 200 with success false and the reason in errors", () {
      for (final name in ["get_price_below_min", "get_price_invalid_coin"]) {
        final raw = fixtureMap("swaptrade", name);
        final response = SwapTradeRateResponse.fromJson(raw);

        expect(response.success, isFalse, reason: name);
        expect(response.data, isNull, reason: name);
        expect(response.errors!.single.msg, (raw["errors"] as List).single["msg"], reason: name);
      }
    });
  });

  group("SwapTradeOrderResponse", () {
    test("parses order, including the numeric status string", () {
      final raw = fixtureMap("swaptrade", "order");
      final response = SwapTradeOrderResponse.fromJson(raw);
      final rawOrder = raw["data"] as Map<String, dynamic>;
      final order = response.data!;

      expect(response.success, isTrue);
      expect(response.status, raw["status"]);
      expect(response.msg, raw["msg"]);
      expect(order.orderId, rawOrder["order_id"]);
      expect(order.coinSend, rawOrder["coin_send"]);
      expect(order.coinReceive, rawOrder["coin_receive"]);
      expect(order.serverAddress, rawOrder["server_address"]);
      expect(order.recipient, rawOrder["recipient"]);
      expect(order.amountSend, double.parse(rawOrder["amount_send"].toString()));
      expect(order.amountReceive, double.parse(rawOrder["amount_receive"].toString()));
      expect(order.memo, rawOrder["memo"]);
      expect(order.createdAt, DateTime.parse(rawOrder["created_at"] as String));
      expect(order.refundAddress, rawOrder["refund_address"]);
      expect(order.outgoingTx, rawOrder["outgoing_tx"]);
      expect(
        order.status,
        TradeState.waitingPayment,
        reason: "swaptrade sends the status as a number in a string, \"1\" here",
      );
    });

    test("an error answers 200 with the status in the body", () {
      final raw = fixtureMap("swaptrade", "order_bad_request");
      final response = SwapTradeOrderResponse.fromJson(raw);

      expect(response.success, isFalse);
      expect(response.status, 400, reason: "the http status was 200");
      expect(response.msg, isNull);
      expect(response.data, isNull);
      expect(response.errors, hasLength(1));
      expect(response.errors!.first.msg, (raw["errors"] as List).first["msg"]);
    });
  });

  group("SwapTradeCreateOrderResponse", () {
    test("parses create_order", () {
      final raw = fixtureMap("swaptrade", "create_order");
      final response = SwapTradeCreateOrderResponse.fromJson(raw);
      final rawData = raw["data"] as Map<String, dynamic>;

      expect(response.success, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.orderId, rawData["order_id"]);
      expect(response.data!.serverAddress, rawData["server_address"]);
      expect(
        response.data!.amountReceive,
        double.parse(rawData["amount_receive"].toString()),
        reason: "amount_receive comes back as a string here",
      );
    });

    test("the order id chains into the order fixture", () {
      final created = SwapTradeCreateOrderResponse.fromJson(
        fixtureMap("swaptrade", "create_order"),
      );
      final fetched = SwapTradeOrderResponse.fromJson(fixtureMap("swaptrade", "order"));

      expect(fetched.data!.orderId, created.data!.orderId);
    });
  });

  group("requests", () {
    test("SwapTradeGetRateRequest serializes the keys the api expects", () {
      final json = const SwapTradeGetRateRequest(
        coinSend: "BTC",
        coinReceive: "XMR",
        amount: "0.01",
        ref: "cake",
      ).toJson();

      expect(json, {
        "coin_send": "BTC",
        "coin_receive": "XMR",
        "amount": "0.01",
        "ref": "cake",
      });
    });

    test("SwapTradeGetRateRequest drops a null amount but still writes a null ref", () {
      final json = const SwapTradeGetRateRequest(coinSend: "BTC", coinReceive: "XMR").toJson();

      expect(json["coin_send"], "BTC");
      expect(json["coin_receive"], "XMR");
      expect(json.containsKey("amount"), isFalse, reason: "it is includeIfNull: false");
      // ref only has defaultValue, which json_serializable applies when reading, not writing,
      // so an unset ref goes out as null rather than as "cake"
      expect(json.containsKey("ref"), isTrue);
      expect(json["ref"], isNull);
    });

    test("SwapTradeGetPriceRequest serializes every key with a fractional markup", () {
      final json = SwapTradeGetPriceRequest(
        coinSend: "BTC",
        coinSendNetwork: "BTC",
        coinReceive: "XMR",
        coinReceiveNetwork: "XMR",
        amountSend: "0.01",
        markup: 1.5,
      ).toJson();

      expect(json, {
        "coin_send": "BTC",
        "coin_send_network": "BTC",
        "coin_receive": "XMR",
        "coin_receive_network": "XMR",
        "amount_send": "0.01",
        "markup": 1.5,
      });
    });

    test("SwapTradeCreateOrderRequest serializes every key", () {
      final json = const SwapTradeCreateOrderRequest(
        coinSend: "ETH",
        coinSendNetwork: "ETH",
        coinReceive: "USDT",
        coinReceiveNetwork: "ETH",
        amountSend: "0.01",
        recipient: "0xrecipient",
        refundAddress: "0xrefund",
        ref: "cake",
        markup: 1.5,
      ).toJson();

      expect(json, {
        "coin_send": "ETH",
        "coin_send_network": "ETH",
        "coin_receive": "USDT",
        "coin_receive_network": "ETH",
        "amount_send": "0.01",
        "recipient": "0xrecipient",
        "refund_address": "0xrefund",
        "ref": "cake",
        "markup": 1.5,
      });
    });

    test("SwapTradeOrderRequest serializes the order id", () {
      expect(const SwapTradeOrderRequest(orderId: "abc").toJson(), {"order_id": "abc"});
    });
  });

  group("SwapTradeAmountConverter", () {
    const converter = SwapTradeAmountConverter();

    test("takes a number", () {
      expect(converter.fromJson(1), 1.0);
      expect(converter.fromJson(1.5), 1.5);
    });

    test("takes a decimal string", () {
      expect(converter.fromJson("565.95000000"), 565.95);
      expect(converter.fromJson("0"), 0.0);
    });

    test("passes NaN through, which an unsupported pair returns", () {
      expect(converter.fromJson("NaN").isNaN, isTrue);
    });

    test("throws on anything else", () {
      expect(() => converter.fromJson(true), throwsA(isA<ArgumentError>()));
      expect(() => converter.fromJson(<String>[]), throwsA(isA<ArgumentError>()));
    });

    test("writes a number", () {
      expect(converter.toJson(1.5), 1.5);
    });
  });

  group("SwapTradeNetworkListConverter", () {
    const converter = SwapTradeNetworkListConverter();

    test("splits a comma separated list", () {
      expect(
        converter.fromJson("USDT_ERC20,TRX_USDT_S2UZ,USDT_BSC"),
        ["USDT_ERC20", "TRX_USDT_S2UZ", "USDT_BSC"],
      );
    });

    test("an empty string is no networks, not one blank one", () {
      expect(converter.fromJson(""), isEmpty);
    });

    test("null is no networks", () {
      expect(converter.fromJson(null), isEmpty);
    });

    test("trims and drops the blanks", () {
      expect(converter.fromJson("A , B ,"), ["A", "B"]);
    });

    test("joins on the way back out", () {
      expect(converter.toJson(["A", "B"]), "A,B");
      expect(converter.toJson([]), isNull);
    });
  });
}
