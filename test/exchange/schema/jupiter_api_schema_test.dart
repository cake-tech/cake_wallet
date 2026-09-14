import "dart:convert";

import "package:cake_wallet/exchange/provider/jupiter/jupiter_api_schema.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void main() {
  group("JupiterOrder", () {
    for (final name in ["order_quote", "order_with_taker"]) {
      test("parses $name field by field", () {
        final raw = fixtureMap("jupiter", name);
        final order = JupiterOrder.fromJson(raw);

        expect(order.requestId, raw["requestId"]);
        expect(order.inputMint, raw["inputMint"]);
        expect(order.outputMint, raw["outputMint"]);
        expect(order.inAmount, BigInt.parse(raw["inAmount"] as String));
        expect(order.outAmount, BigInt.parse(raw["outAmount"] as String));
        expect(order.otherAmountThreshold, BigInt.parse(raw["otherAmountThreshold"] as String));
        expect(order.swapType, JupiterSwapType.aggregator);
        expect(order.swapMode, JupiterSwapMode.exactIn);
        expect(order.slippageBps, raw["slippageBps"]);
        expect(order.priceImpactPct, raw["priceImpactPct"]);
        expect(order.priceImpact, raw["priceImpact"]);
        expect(order.transaction, raw["transaction"]);
        expect(order.taker, raw["taker"]);
        expect(order.router, raw["router"]);
        expect(order.mode, raw["mode"]);
        expect(order.gasless, raw["gasless"]);
        expect(order.jitOptimized, raw["jitOptimized"]);
        expect(order.guaranteedPrice, raw["guaranteedPrice"]);
        expect(order.feeMint, raw["feeMint"]);
        expect(order.feeBps, raw["feeBps"]);
        expect(order.signatureFeeLamports, raw["signatureFeeLamports"]);
        expect(order.signatureFeePayer, raw["signatureFeePayer"]);
        expect(order.prioritizationFeeLamports, raw["prioritizationFeeLamports"]);
        expect(order.prioritizationFeePayer, raw["prioritizationFeePayer"]);
        expect(order.rentFeeLamports, raw["rentFeeLamports"]);
        expect(order.rentFeePayer, raw["rentFeePayer"]);
        expect(order.inUsdValue, raw["inUsdValue"]);
        expect(order.outUsdValue, raw["outUsdValue"]);
        expect(order.swapUsdValue, raw["swapUsdValue"]);
        expect(order.totalTime, raw["totalTime"]);
        expect(order.errorCode, raw["errorCode"]);
        expect(order.errorMessage, raw["errorMessage"]);
        expect(order.error, raw["error"]);

        expect(order.platformFee, isNotNull);
        expect(order.platformFee!.feeBps, raw["platformFee"]["feeBps"]);
        expect(order.platformFee!.feeMint, raw["platformFee"]["feeMint"]);
      });
    }

    test("parses the whole route plan", () {
      final raw = fixtureMap("jupiter", "order_quote");
      final order = JupiterOrder.fromJson(raw);
      final rawPlan = raw["routePlan"] as List<dynamic>;

      expect(order.routePlan, hasLength(rawPlan.length));

      for (var i = 0; i < rawPlan.length; i++) {
        final rawStep = rawPlan[i] as Map<String, dynamic>;
        final step = order.routePlan![i];
        final rawInfo = rawStep["swapInfo"] as Map<String, dynamic>;

        expect(step.percent, rawStep["percent"]);
        expect(step.bps, rawStep["bps"]);
        expect(step.usdValue, rawStep["usdValue"]);
        expect(step.swapInfo.ammKey, rawInfo["ammKey"]);
        expect(step.swapInfo.label, rawInfo["label"]);
        expect(step.swapInfo.inputMint, rawInfo["inputMint"]);
        expect(step.swapInfo.outputMint, rawInfo["outputMint"]);
        expect(step.swapInfo.inAmount, BigInt.parse(rawInfo["inAmount"] as String));
        expect(step.swapInfo.outAmount, BigInt.parse(rawInfo["outAmount"] as String));
      }
    });

    test("a quote with no taker has no transaction, no fees and no slippage", () {
      final order = JupiterOrder.fromJson(fixtureMap("jupiter", "order_quote"));

      expect(order.taker, isNull);
      expect(order.transaction, isNull);
      expect(order.slippageBps, 0, reason: "slippage is only estimated once a taker is known");
      expect(order.signatureFeeLamports, 0);
      expect(order.prioritizationFeeLamports, 0);
      expect(order.rentFeeLamports, 0);
    });

    test("a quote with a taker gets a slippage estimate", () {
      final withTaker = JupiterOrder.fromJson(fixtureMap("jupiter", "order_with_taker"));

      expect(withTaker.taker, isNotNull);
      expect(withTaker.slippageBps, greaterThan(0));
      expect(
        withTaker.otherAmountThreshold! < withTaker.outAmount,
        isTrue,
        reason: "the threshold is the out amount less the slippage",
      );
    });

    test("a rejected order is still a 200 body with the quote fields intact", () {
      final raw = fixtureMap("jupiter", "order_with_taker");

      // the taker used by the fixture script holds nothing, so the api answers errorCode 1
      if (raw["errorCode"] != null) {
        final order = JupiterOrder.fromJson(raw);

        expect(order.errorCode, 1, reason: "1 is insufficient funds");
        expect(order.errorMessage, isNotNull);
        expect(order.transaction, isEmpty, reason: "empty rather than null when rejected");
        expect(order.outAmount, greaterThan(BigInt.zero), reason: "the quote survives");
      }
    });
  });

  group("JupiterErrorResponse", () {
    test("parses the 400 body a bad amount answers with", () {
      final raw = fixtureMap("jupiter", "order_bad_amount");
      final error = JupiterErrorResponse.fromJson(raw);

      expect(error.requestId, raw["requestId"]);
      expect(error.error, raw["error"]);
      expect(raw.containsKey("outAmount"), isFalse, reason: "none of the quote fields are there");
    });

    test("parses a 500 body, which does not even carry a requestId", () {
      const body = '{"error":"Something unexpected occurred"}';
      final error = JupiterErrorResponse.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(error.requestId, isNull);
      expect(error.error, "Something unexpected occurred");
    });
  });

  group("JupiterExecuteResponse", () {
    // /ultra/v1/execute broadcasts a transaction, so there is no fixture for it. these bodies
    // are the documented shapes
    test("parses a success", () {
      const body = '{"status":"Success","signature":"5xy","slot":308506759,"code":0,'
          '"inputAmountResult":"100000000","outputAmountResult":"7304538",'
          '"swapEvents":[{"inputMint":"So1","inputAmount":"100000000","outputMint":"EPj",'
          '"outputAmount":"7304538"}]}';
      final response = JupiterExecuteResponse.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(response.status, JupiterExecuteStatus.success);
      expect(response.signature, "5xy");
      expect(response.slot, 308506759);
      expect(response.code, 0);
      expect(response.error, isNull);
      expect(response.inputAmountResult, BigInt.from(100000000));
      expect(response.outputAmountResult, BigInt.from(7304538));
      expect(response.swapEvents, hasLength(1));
      expect(response.swapEvents!.first.inputMint, "So1");
      expect(response.swapEvents!.first.inputAmount, BigInt.from(100000000));
      expect(response.swapEvents!.first.outputMint, "EPj");
      expect(response.swapEvents!.first.outputAmount, BigInt.from(7304538));
    });

    test("parses a failure, which still carries a signature", () {
      const body = '{"status":"Failed","signature":"5xy","slot":"308506759","code":-1,'
          '"error":"Slippage tolerance exceeded"}';
      final response = JupiterExecuteResponse.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(response.status, JupiterExecuteStatus.failed);
      expect(response.signature, "5xy");
      expect(response.slot, 308506759, reason: "slot arrives as a string here");
      expect(response.code, -1);
      expect(response.error, "Slippage tolerance exceeded");
      expect(response.outputAmountResult, isNull);
    });

    test("parses the pending and processing states the provider polls on", () {
      for (final status in ["Pending", "Processing"]) {
        final response = JupiterExecuteResponse.fromJson(
          json.decode('{"status":"$status"}') as Map<String, dynamic>,
        );

        expect(
          response.status,
          status == "Pending" ? JupiterExecuteStatus.pending : JupiterExecuteStatus.processing,
        );
        expect(response.signature, isNull);
      }
    });

    test("an unrecognised status falls back to unknown", () {
      final response = JupiterExecuteResponse.fromJson(
        json.decode('{"status":"Something"}') as Map<String, dynamic>,
      );

      expect(response.status, JupiterExecuteStatus.unknown);
    });
  });

  group("requests", () {
    test("JupiterOrderRequest stringifies the amount, which Uri.https needs", () {
      final json = JupiterOrderRequest(
        inputMint: "So1",
        outputMint: "EPj",
        amount: BigInt.from(100000000),
        taker: "taker",
        referralAccount: "ref",
        referralFee: "50",
      ).toJson();

      expect(json, {
        "inputMint": "So1",
        "outputMint": "EPj",
        "amount": "100000000",
        "taker": "taker",
        "referralAccount": "ref",
        "referralFee": "50",
      });
      expect(json.values.whereType<String>(), hasLength(json.length));
    });

    test("JupiterOrderRequest drops the optional keys for a quote only call", () {
      final json = JupiterOrderRequest(
        inputMint: "So1",
        outputMint: "EPj",
        amount: BigInt.one,
      ).toJson();

      expect(json.keys, ["inputMint", "outputMint", "amount"]);
    });

    test("JupiterExecuteRequest serializes the signed transaction and request id", () {
      expect(
        const JupiterExecuteRequest(signedTransaction: "AQAB", requestId: "019f").toJson(),
        {"signedTransaction": "AQAB", "requestId": "019f"},
      );
    });
  });

  group("JupiterBaseUnitConverter", () {
    const converter = JupiterBaseUnitConverter();

    test("reads the string form the order endpoint uses", () {
      expect(converter.fromJson("100000000"), BigInt.from(100000000));
    });

    test("reads a number too, since the execute fields are undocumented", () {
      expect(converter.fromJson(7304538), BigInt.from(7304538));
    });

    test("keeps precision past what a double could hold", () {
      const huge = "123456789012345678901234567890";

      expect(converter.fromJson(huge), BigInt.parse(huge));
      expect(converter.toJson(BigInt.parse(huge)), huge);
    });

    test("throws on anything else", () {
      expect(() => converter.fromJson(true), throwsA(isA<ArgumentError>()));
    });
  });

  group("JupiterLooseIntConverter", () {
    const converter = JupiterLooseIntConverter();

    test("reads a number", () {
      expect(converter.fromJson(308506759), 308506759);
      expect(converter.fromJson(-1), -1);
    });

    test("reads a numeric string, since slot and code are undocumented", () {
      expect(converter.fromJson("308506759"), 308506759);
    });

    test("truncates a double rather than throwing", () {
      expect(converter.fromJson(1.9), 1);
    });

    test("throws on anything else", () {
      expect(() => converter.fromJson(false), throwsA(isA<ArgumentError>()));
    });

    test("writes a number", () {
      expect(converter.toJson(7), 7);
    });
  });
}
