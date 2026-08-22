import "dart:convert";

import "package:cake_wallet/exchange/provider/changenow/changenow_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void main() {
  group("ChangeNowRangeResponse", () {
    test("parses range field by field", () {
      final raw = fixtureMap("changenow", "range");
      final range = ChangeNowRangeResponse.fromJson(raw);

      expect(range.fromCurrency, raw["fromCurrency"]);
      expect(range.fromNetwork, raw["fromNetwork"]);
      expect(range.toCurrency, raw["toCurrency"]);
      expect(range.toNetwork, raw["toNetwork"]);
      expect(range.flow, ChangeNowFlow.standard);
      expect(range.minAmount, raw["minAmount"]);
      expect(range.maxAmount, raw["maxAmount"]);
    });

    test("a null maxAmount means no upper limit", () {
      final raw = fixtureMap("changenow", "range");

      expect(raw["maxAmount"], isNull, reason: "btc to xmr has no cap");
      expect(ChangeNowRangeResponse.fromJson(raw).maxAmount, isNull);
    });
  });

  group("ChangeNowEstimatedAmountResponse", () {
    test("parses estimated_amount field by field", () {
      final raw = fixtureMap("changenow", "estimated_amount");
      final estimate = ChangeNowEstimatedAmountResponse.fromJson(raw);

      expect(estimate.fromCurrency, raw["fromCurrency"]);
      expect(estimate.fromNetwork, raw["fromNetwork"]);
      expect(estimate.toCurrency, raw["toCurrency"]);
      expect(estimate.toNetwork, raw["toNetwork"]);
      expect(estimate.flow, ChangeNowFlow.standard);
      expect(estimate.type, ChangeNowExchangeType.direct);
      expect(estimate.rateId, raw["rateId"]);
      expect(estimate.validUntil, isNull);
      expect(estimate.transactionSpeedForecast, raw["transactionSpeedForecast"]);
      expect(estimate.warningMessage, raw["warningMessage"]);
      expect(estimate.depositFee, raw["depositFee"]);
      expect(estimate.withdrawalFee, raw["withdrawalFee"]);
      expect(estimate.userId, raw["userId"]);
      expect(estimate.fromAmount, raw["fromAmount"]);
      expect(estimate.toAmount, raw["toAmount"]);
    });

    test("a floating rate has no rateId or validUntil", () {
      final estimate = ChangeNowEstimatedAmountResponse.fromJson(
        fixtureMap("changenow", "estimated_amount"),
      );

      expect(estimate.flow, ChangeNowFlow.standard);
      expect(estimate.rateId, isNull);
      expect(estimate.validUntil, isNull);
    });
  });

  group("ChangeNowErrorResponse", () {
    test("parses the below minimum body", () {
      final raw = fixtureMap("changenow", "estimated_amount_below_min");
      final error = ChangeNowErrorResponse.fromJson(raw);

      expect(error.error, raw["error"]);
      expect(error.message, raw["message"]);
    });

    test("the body also carries the range that was violated, which the schema ignores", () {
      final raw = fixtureMap("changenow", "estimated_amount_below_min");

      expect(raw["payload"]["range"]["minAmount"], isNotNull);
    });
  });

  group("ChangeNowCreateExchangeResponse", () {
    test("parses create_exchange field by field", () {
      final raw = fixtureMap("changenow", "create_exchange");
      final created = ChangeNowCreateExchangeResponse.fromJson(raw);

      expect(created.id, raw["id"]);
      expect(created.fromAmount, raw["fromAmount"]);
      expect(created.toAmount, raw["toAmount"]);
      expect(created.flow, ChangeNowFlow.standard);
      expect(created.type, ChangeNowExchangeType.direct);
      expect(created.payinAddress, raw["payinAddress"]);
      expect(created.payoutAddress, raw["payoutAddress"]);
      expect(created.fromCurrency, raw["fromCurrency"]);
      expect(created.toCurrency, raw["toCurrency"]);
      expect(created.fromNetwork, raw["fromNetwork"]);
      expect(created.toNetwork, raw["toNetwork"]);
      expect(created.refundAddress, raw["refundAddress"]);
      expect(created.payinExtraId, raw["payinExtraId"]);
      expect(created.payoutExtraId, raw["payoutExtraId"]);
      expect(
        created.validUntil,
        raw["validUntil"] == null ? isNull : DateTime.parse(raw["validUntil"] as String),
      );
    });
  });

  group("ChangeNowTransactionResponse", () {
    test("parses by_id field by field", () {
      final raw = fixtureMap("changenow", "by_id");
      final tx = ChangeNowTransactionResponse.fromJson(raw);

      expect(tx.id, raw["id"]);
      expect(tx.status, TradeState.deserialize(raw: raw["status"] as String));
      expect(tx.actionsAvailable, raw["actionsAvailable"]);
      expect(tx.fromCurrency, raw["fromCurrency"]);
      expect(tx.fromNetwork, raw["fromNetwork"]);
      expect(tx.toCurrency, raw["toCurrency"]);
      expect(tx.toNetwork, raw["toNetwork"]);
      expect(tx.expectedAmountFrom, raw["expectedAmountFrom"]);
      expect(tx.expectedAmountTo, raw["expectedAmountTo"]);
      expect(tx.amountFrom, raw["amountFrom"]);
      expect(tx.amountTo, raw["amountTo"]);
      expect(tx.payinAddress, raw["payinAddress"]);
      expect(tx.payoutAddress, raw["payoutAddress"]);
      expect(tx.payinExtraId, raw["payinExtraId"]);
      expect(tx.payoutExtraId, raw["payoutExtraId"]);
      expect(tx.refundAddress, raw["refundAddress"]);
      expect(tx.refundExtraId, raw["refundExtraId"]);
      expect(tx.createdAt, DateTime.parse(raw["createdAt"] as String));
      expect(tx.payinHash, raw["payinHash"]);
      expect(tx.payoutHash, raw["payoutHash"]);
      expect(tx.fromLegacyTicker, raw["fromLegacyTicker"]);
      expect(tx.toLegacyTicker, raw["toLegacyTicker"]);
      expect(tx.refundHash, raw["refundHash"]);
      expect(tx.refundAmount, raw["refundAmount"]);
      expect(tx.userId, raw["userId"]);
    });

    test("a trade with no deposit yet has expected amounts but no actual ones", () {
      final tx = ChangeNowTransactionResponse.fromJson(fixtureMap("changenow", "by_id"));

      expect(tx.status, TradeState.waiting);
      expect(tx.expectedAmountFrom, isNotNull);
      expect(tx.amountFrom, isNull, reason: "nothing has arrived yet");
      expect(tx.amountTo, isNull);
    });

    test("the id chains from the create fixture", () {
      final created = ChangeNowCreateExchangeResponse.fromJson(
        fixtureMap("changenow", "create_exchange"),
      );
      final fetched = ChangeNowTransactionResponse.fromJson(fixtureMap("changenow", "by_id"));

      expect(fetched.id, created.id);
      expect(fetched.payinAddress, created.payinAddress);
    });
  });

  group("enums", () {
    test("flow maps both wire values", () {
      final standard = ChangeNowRangeResponse.fromJson(
        json.decode('{"fromCurrency":"btc","fromNetwork":"btc","toCurrency":"xmr",'
            '"toNetwork":"xmr","flow":"standard"}') as Map<String, dynamic>,
      );
      final fixed = ChangeNowRangeResponse.fromJson(
        json.decode('{"fromCurrency":"btc","fromNetwork":"btc","toCurrency":"xmr",'
            '"toNetwork":"xmr","flow":"fixed-rate"}') as Map<String, dynamic>,
      );

      expect(standard.flow, ChangeNowFlow.standard);
      expect(fixed.flow, ChangeNowFlow.fixedRate);
    });

    test("an unrecognised flow falls back to unknown", () {
      final range = ChangeNowRangeResponse.fromJson(
        json.decode('{"fromCurrency":"btc","fromNetwork":"btc","toCurrency":"xmr",'
            '"toNetwork":"xmr","flow":"something-new"}') as Map<String, dynamic>,
      );

      expect(range.flow, ChangeNowFlow.unknown);
    });
  });

  group("requests", () {
    test("ChangeNowRangeRequest serializes the flow as its wire value", () {
      expect(
        const ChangeNowRangeRequest(
          fromCurrency: "btc",
          toCurrency: "xmr",
          fromNetwork: "btc",
          toNetwork: "xmr",
          flow: ChangeNowFlow.standard,
        ).toJson(),
        {
          "fromCurrency": "btc",
          "toCurrency": "xmr",
          "fromNetwork": "btc",
          "toNetwork": "xmr",
          "flow": "standard",
        },
      );
    });

    test("ChangeNowRangeRequest writes fixed-rate, not the dart name", () {
      final json = const ChangeNowRangeRequest(
        fromCurrency: "btc",
        toCurrency: "xmr",
        fromNetwork: "btc",
        toNetwork: "xmr",
        flow: ChangeNowFlow.fixedRate,
      ).toJson();

      expect(json["flow"], "fixed-rate");
    });

    test("ChangeNowEstimatedAmountRequest omits the amount it is not using", () {
      final json = const ChangeNowEstimatedAmountRequest(
        fromCurrency: "btc",
        toCurrency: "xmr",
        fromNetwork: "btc",
        toNetwork: "xmr",
        flow: ChangeNowFlow.standard,
        type: ChangeNowExchangeType.direct,
        fromAmount: "0.01",
      ).toJson();

      expect(json["type"], "direct");
      expect(json["fromAmount"], "0.01");
      expect(json.containsKey("toAmount"), isFalse);
      expect(json.containsKey("useRateId"), isFalse);
    });

    test("ChangeNowCreateExchangeRequest nests the payload object", () {
      final json = const ChangeNowCreateExchangeRequest(
        fromCurrency: "eth",
        toCurrency: "usdt",
        fromNetwork: "eth",
        toNetwork: "eth",
        address: "0xpayout",
        flow: ChangeNowFlow.standard,
        type: ChangeNowExchangeType.direct,
        fromAmount: "0.01",
        refundAddress: "0xrefund",
        payload: ChangeNowCreateExchangePayload(
          app: "cakewallet",
          device: "android",
          distribution: "github",
          version: 4270,
        ),
      ).toJson();

      expect(json["address"], "0xpayout");
      expect(json["refundAddress"], "0xrefund");
      expect(json["payload"], {
        "app": "cakewallet",
        "device": "android",
        "distribution": "github",
        "version": 4270,
      });
      expect(json.containsKey("contactEmail"), isFalse);
    });

    test("ChangeNowByIdRequest serializes the id", () {
      expect(const ChangeNowByIdRequest(id: "abc").toJson(), {"id": "abc"});
    });
  });
}
