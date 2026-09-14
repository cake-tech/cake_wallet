import "dart:convert";

import "package:cake_wallet/exchange/provider/xoswap/xoswap_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void main() {
  group("XOSwapAsset", () {
    test("parses every asset in assets", () {
      final raw = fixtureList("xoswap", "assets");
      final assets = raw
          .map((e) => XOSwapAsset.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(assets, hasLength(raw.length));

      for (var i = 0; i < raw.length; i++) {
        final rawAsset = raw[i] as Map<String, dynamic>;
        final asset = assets[i];

        expect(asset.id, rawAsset["id"]);
        expect(asset.symbol, rawAsset["symbol"]);
        expect(asset.meta, rawAsset["meta"]);
      }
    });

    test("meta carries the network identifier the provider matches on", () {
      final first = XOSwapAsset.fromJson(
        (fixtureList("xoswap", "assets").first) as Map<String, dynamic>,
      );

      expect(first.meta, isNotNull);
      expect(first.meta!["contractAddress"], isNotNull);
    });

    test("the response also carries name, network and decimals, which the schema ignores", () {
      final rawAsset = fixtureList("xoswap", "assets").first as Map<String, dynamic>;

      expect(rawAsset.keys, containsAll(<String>["name", "network", "decimals"]));
    });
  });

  group("XOSwapRate", () {
    test("parses every rate in pair_rates", () {
      final raw = fixtureList("xoswap", "pair_rates");
      final rates = raw.map((e) => XOSwapRate.fromJson(e as Map<String, dynamic>)).toList();

      expect(rates, hasLength(raw.length));

      for (var i = 0; i < raw.length; i++) {
        final rawRate = raw[i] as Map<String, dynamic>;
        final rate = rates[i];

        expect(rate.amount.value, (rawRate["amount"]["value"] as num).toDouble());
        expect(rate.amount.assetId, rawRate["amount"]["assetId"]);
        expect(rate.minerFee.value, (rawRate["minerFee"]["value"] as num).toDouble());
        expect(rate.minerFee.assetId, rawRate["minerFee"]["assetId"]);
        expect(rate.min.value, (rawRate["min"]["value"] as num).toDouble());
        expect(rate.min.assetId, rawRate["min"]["assetId"]);
        expect(rate.max.value, (rawRate["max"]["value"] as num).toDouble());
        expect(rate.max.assetId, rawRate["max"]["assetId"]);
        expect(
          rate.expiry,
          DateTime.fromMillisecondsSinceEpoch(rawRate["expiry"] as int, isUtc: true),
          reason: "expiry is milliseconds since epoch",
        );
      }
    });

    test("the best output is computable from a rate, as the docs describe it", () {
      final rates = fixtureList("xoswap", "pair_rates")
          .map((e) => XOSwapRate.fromJson(e as Map<String, dynamic>))
          .toList();
      const fromAmount = 0.01;
      final usable = rates.where((r) => fromAmount >= r.min.value && fromAmount <= r.max.value);

      expect(usable, isNotEmpty);
      for (final rate in usable) {
        expect(fromAmount * rate.amount.value - rate.minerFee.value, greaterThan(0));
      }
    });

    test("a rate also carries id, pairId and features, which the schema ignores", () {
      final rawRate = fixtureList("xoswap", "pair_rates").first as Map<String, dynamic>;

      expect(rawRate.keys, containsAll(<String>["id", "pairId", "features"]));
    });
  });

  group("XOSwapOrder", () {
    for (final name in ["order", "create_order"]) {
      test("parses $name field by field", () {
        final raw = fixtureMap("xoswap", name);
        final order = XOSwapOrder.fromJson(raw);

        expect(order.id, raw["id"]);
        expect(order.pairId, raw["pairId"]);
        expect(order.status, TradeState.deserialize(raw: raw["status"] as String));
        expect(order.payInAddress, raw["payInAddress"]);
        expect(order.fromAddress, raw["fromAddress"]);
        expect(order.toAddress, raw["toAddress"]);
        expect(order.fromAddressTag, raw["fromAddressTag"]);
        expect(order.toAddressTag, raw["toAddressTag"]);
        expect(order.payInAddressTag, raw["payInAddressTag"]);
        expect(order.fromTransactionId, raw["fromTransactionId"]);
        expect(order.toTransactionId, raw["toTransactionId"]);
        expect(order.providerOrderId, raw["providerOrderId"]);
        expect(order.rateId, raw["rateId"]);
        expect(order.message, raw["message"]);
        expect(order.createdAt, DateTime.parse(raw["createdAt"] as String));
        expect(order.updatedAt, DateTime.parse(raw["updatedAt"] as String));
        expect(order.extraFeatures, raw["extraFeatures"]);

        expect(order.amount.assetId, raw["amount"]["assetId"]);
        expect(order.amount.value, double.parse(raw["amount"]["value"].toString()));
        expect(order.toAmount, isNotNull);
        expect(order.toAmount!.assetId, raw["toAmount"]["assetId"]);
        expect(order.toAmount!.value, double.parse(raw["toAmount"]["value"].toString()));
      });
    }

    test("an order amount arrives as a string while a rate amount arrives as a number", () {
      final orderValue = fixtureMap("xoswap", "order")["amount"]["value"];
      final rateValue = (fixtureList("xoswap", "pair_rates").first
          as Map<String, dynamic>)["amount"]["value"];

      expect(orderValue, isA<String>());
      expect(rateValue, isA<num>());
    });

    test("the created order is the one the order fixture fetches", () {
      final created = XOSwapOrder.fromJson(fixtureMap("xoswap", "create_order"));
      final fetched = XOSwapOrder.fromJson(fixtureMap("xoswap", "order"));

      expect(fetched.id, created.id);
      expect(fetched.payInAddress, created.payInAddress);
    });
  });

  group("XOSwapErrorResponse", () {
    test("parses the body a rejected create answers with", () {
      // a real 400 from POST /v3/orders
      const body = '{"code":"BAD_REQUEST","status":400,"orderId":"4GAo57XO7gXlZdX",'
          '"details":"Could not create order"}';
      final error = XOSwapErrorResponse.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(error.code, "BAD_REQUEST");
      expect(error.details, "Could not create order");
      expect(error.message, isNull, reason: "this api uses details, not message");
      expect(error.error, isNull);
    });

    test("parses a not found body", () {
      const body = '{"code":"NOT_FOUND","message":"Order not found"}';
      final error = XOSwapErrorResponse.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(error.code, "NOT_FOUND");
      expect(error.message, "Order not found");
    });
  });

  group("requests", () {
    test("XOSwapAssetsRequest serializes the query params", () {
      expect(
        const XOSwapAssetsRequest(networks: "ethereum", query: "USDT").toJson(),
        {"networks": "ethereum", "query": "USDT"},
      );
    });

    test("XOSwapAssetsRequest drops the nulls, so Uri.https stays happy", () {
      final json = const XOSwapAssetsRequest().toJson();

      expect(json, isEmpty);
    });

    test("XOSwapCreateOrderRequest serializes every key", () {
      final json = const XOSwapCreateOrderRequest(
        pairId: "ETH_USDT",
        fromAmount: "0.01",
        toAmount: "30",
        fromAddress: "0xfrom",
        toAddress: "0xto",
        fromAddressTag: "tag1",
        toAddressTag: "tag2",
        slippage: 3,
      ).toJson();

      expect(json, {
        "pairId": "ETH_USDT",
        "fromAmount": "0.01",
        "toAmount": "30",
        "fromAddress": "0xfrom",
        "fromAddressTag": "tag1",
        "toAddress": "0xto",
        "toAddressTag": "tag2",
        "slippage": 3.0,
      });
    });

    test("XOSwapCreateOrderRequest omits the optional tags and slippage", () {
      final json = const XOSwapCreateOrderRequest(
        pairId: "ETH_USDT",
        fromAmount: "0.01",
        toAmount: "30",
        fromAddress: "0xfrom",
        toAddress: "0xto",
      ).toJson();

      expect(json.containsKey("fromAddressTag"), isFalse);
      expect(json.containsKey("toAddressTag"), isFalse);
      expect(json.containsKey("slippage"), isFalse);
    });
  });

  group("XOSwapAmountValueConverter", () {
    const converter = XOSwapAmountValueConverter();

    test("takes the number form the rates endpoint sends", () {
      expect(converter.fromJson(33.14218692377834), 33.14218692377834);
      expect(converter.fromJson(1), 1.0);
    });

    test("takes the string form the orders endpoint sends", () {
      expect(converter.fromJson("0.1"), 0.1);
      expect(converter.fromJson("186.64530717"), 186.64530717);
    });

    test("throws on anything else", () {
      expect(() => converter.fromJson(true), throwsA(isA<ArgumentError>()));
    });

    test("writes a number", () {
      expect(converter.toJson(0.1), 0.1);
    });
  });
}
